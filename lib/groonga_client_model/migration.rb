# Copyright (C) 2017  Kouhei Sutou <kou@clear-code.com>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

require "benchmark"

module GroongaClientModel
  class MigrationError < Error
  end

  class IrreversibleMigrationError < MigrationError
  end

  class IllegalMigrationNameError < MigrationError
    class << self
      def validate(name)
        case name
        when /\A[_a-z0-9]+\z/
          # OK
        else
          raise new(name)
        end
      end
    end

    attr_reader :name
    def initialize(name)
      @name = name
      message = "Illegal name for migration file: #{name}\n"
      message << "\t(only lower case letters, numbers, and '_' allowed)."
      super(message)
    end
  end

  class Migration
    attr_accessor :output
    attr_reader :client

    def initialize(client)
      @client = client
      @output = nil
      @reverting = false
      @pending_actions = []
    end

    def up
      change
    end

    def down
      revert do
        change
      end
    end

    def create_table(name,
                     type: nil,
                     key_type: nil,
                     tokenizer: nil,
                     default_tokenizer: nil,
                     normalizer: nil,
                     propose: nil)
      if @reverting
        @pending_actions << [:remove_table, name]
        return
      end

      case propose
      when :full_text_search
        type ||= :patricia_trie
        tokenizer ||= :bigram
        normalizer ||= :auto
      end

      type = normalize_table_type(type || :array)
      if type != "TABLE_NO_KEY" and key_type.nil?
        key_type ||= "ShortText"
      end
      key_type = normalize_type(key_type)
      if type != "TABLE_NO_KEY" and key_type == "ShortText"
        tokenizer ||= default_tokenizer
        tokenizer = normalize_tokenizer(tokenizer)
        normalizer = normalize_normalizer(normalizer)
      end
      options = {type: type}
      options[:key_type] = key_type if key_type
      options[:tokenizer] = tokenizer if tokenizer
      options[:normalizer] = normalizer if normalizer
      report(__method__, [name, options]) do
        @client.request(:table_create).
          parameter(:name, name).
          flags_parameter(:flags, [type]).
          parameter(:key_type, key_type).
          parameter(:default_tokenizer, tokenizer).
          parameter(:normalizer, normalizer).
          response
      end

      yield(CreateTableMigration.new(self, name)) if block_given?
    end

    def remove_table(name)
      if @reverting
        raise IrreversibleMigrationError, "can't revert remove_table(#{name})"
      end

      report(__method__, [name]) do
        @client.request(:table_remove).
          parameter(:name, name).
          response
      end
    end

    def copy_table(from_table_name, to_table_name)
      if @reverting
        message = "can't revert copy_table(#{from_table_name}, #{to_table_name})"
        raise IrreversibleMigrationError, message
      end

      report(__method__, [from_table_name, to_table_name]) do
        @client.request(:table_copy).
          parameter(:from_name, from_table_name).
          parameter(:to_name, to_table_name).
          response
      end
    end

    def add_column(table_name, column_name, value_type,
                   flags: nil,
                   type: nil,
                   sources: nil,
                   source: nil)
      if @reverting
        @pending_actions << [:remove_column, table_name, column_name]
        return
      end

      value_type = normalize_type(value_type)
      type = normalize_column_type(type || :scalar)
      sources ||= source || []
      flags = Array(flags) | [type]
      if type == "COLUMN_INDEX"
        schema = GroongaClientModel::Schema.new
        case schema.tables[table_name].tokenizer
        when nil, "TokenDelimit"
          # do nothing
        else
          flags << "WITH_POSITION"
        end
        if sources.size > 1
          flags << "WITH_SECTION"
        end
      end
      options = {
        flags: flags,
        value_type: value_type,
      }
      options[:sources] = sources unless sources.blank?
      report(__method__, [table_name, column_name, options]) do
        @client.request(:column_create).
          parameter(:table, table_name).
          parameter(:name, column_name).
          flags_parameter(:flags, flags).
          parameter(:type, value_type).
          values_parameter(:source, sources).
          response
      end
    end

    def remove_column(table_name, column_name)
      if @reverting
        message = "can't revert remove_column(#{table_name}, #{column_name})"
        raise IrreversibleMigrationError, message
      end

      report(__method__, [table_name, column_name]) do
        @client.request(:column_remove).
          parameter(:table_name, table_name).
          parameter(:name, column_name).
          response
      end
    end

    def add_timestamp_columns(table_name)
      add_column(table_name, :created_at, :time)
      add_column(table_name, :updated_at, :time)
    end

    def remove_timestamp_columns(table_name)
      remove_column(table_name, :updated_at)
      remove_column(table_name, :created_at)
    end

    def copy_column(from_full_column_name,
                    to_full_column_name)
      if @reverting
        message = "can't revert copy_column"
        message << "(#{from_full_column_name}, #{to_full_column_name})"
        raise IrreversibleMigrationError, message
      end

      from_table_name, from_column_name = from_full_column_name.split(".", 2)
      to_table_name, to_column_name = to_full_column_name.split(".", 2)
      report(__method__, [from_full_column_name, to_full_column_name]) do
        @client.request(:column_copy).
          parameter(:from_table, from_table_name).
          parameter(:from_name, from_column_name).
          parameter(:to_table, to_table_name).
          parameter(:to_name, to_column_name).
          response
      end
    end

    def set_config(key, value)
      if @reverting
        message = "can't revert set_config(#{key.inspect}, #{value.inspect})"
        raise IrreversibleMigrationError, message
      end

      report(__method__, [key, value]) do
        @client.request(:config_set).
          parameter(:key, key).
          parameter(:value, value).
          response
      end
    end

    def delete_config(key)
      if @reverting
        message = "can't revert delete_config(#{key.inspect})"
        raise IrreversibleMigrationError, message
      end

      report(__method__, [key]) do
        @client.request(:config_delete).
          parameter(:key, key).
          response
      end
    end

    def load(table_name, values, options={})
      if @reverting
        message = "can't revert load(#{table_name.inspect})"
        raise IrreversibleMigrationError, message
      end

      case values
      when Hash
        json_values = [values].to_json
      when Array
        json_values = values.to_json
      else
        json_values = values
      end
      report(__method__, [table_name]) do
        @client.request(:load).
          parameter(:table, table_name).
          values_parameter(:columns, options[:columns]).
          parameter(:values, json_values).
          response
      end
    end

    def exist?(name)
      @client.request(:object_exist).
        parameter(:name, name).
        response.
        body
    end

    def reverting?
      @reverting
    end

    private
    def puts(*args)
      if @output
        @output.puts(*args)
      else
        super
      end
    end

    def report(method_name, arguments)
      argument_list = arguments.collect(&:inspect).join(", ")
      puts("-- #{method_name}(#{argument_list})")
      time = Benchmark.measure do
        yield
      end
      puts("   -> %.4fs" % time.real)
    end

    def revert
      @pending_actions.clear
      @reverting = true
      begin
        yield
      ensure
        @reverting = false
      end
      @pending_actions.reverse_each do |action|
        public_send(*action)
      end
      @pending_actions.clear
    end

    def normalize_table_type(type)
      case type.to_s
      when "array", /\A(?:TABLE_)?NO_KEY\z/i
        "TABLE_NO_KEY"
      when "hash", "hash_table", /\A(?:TABLE_)?HASH_KEY\z/i
        "TABLE_HASH_KEY"
      when "pat", "patricia_trie", /\A(?:TABLE_)?PAT_KEY\z/i
        "TABLE_PAT_KEY"
      when "dat", "double_array_trie", /\A(?:TABLE_)?DAT_KEY\z/i
        "TABLE_DAT_KEY"
      else
        message = "table type must be one of "
        message << "[:array, :hash_table, :patricia_trie, :double_array_trie]: "
        message << "#{type.inspect}"
        raise ArgumentError, message
      end
    end

    def normalize_column_type(type)
      case type.to_s
      when "scalar", /\A(?:COLUMN_)?SCALAR\z/i
        "COLUMN_SCALAR"
      when "vector", /\A(?:COLUMN_)?VECTOR\z/i
        "COLUMN_VECTOR"
      when "index", /\A(?:COLUMN_)?INDEX\z/i
        "COLUMN_INDEX"
      else
        message = "table type must be one of "
        message << "[:array, :hash_table, :patricia_trie, :double_array_trie]: "
        message << "#{type.inspect}"
        raise ArgumentError, message
      end
    end

    def normalize_type(type)
      case type.to_s
      when /\Abool(?:ean)?\z/i
        "Bool"
      when /\Aint(8|16|32|64)\z/i
        "Int#{$1}"
      when /\Auint(8|16|32|64)\z/i
        "UInt#{$1}"
      when /\Afloat\z/i
        "Float"
      when /\Atime\z/i
        "Time"
      when /\Ashort_?text\z/i
        "ShortText"
      when /\Atext\z/i
        "Text"
      when /\Along_?text\z/i
        "LongText"
      when /\Atokyo_?geo_?point\z/i
        "TokyoGeoPoint"
      when /\A(?:wgs84)?_?geo_?point\z/i
        "WGS84GeoPoint"
      else
        type
      end
    end

    def normalize_tokenizer(tokenizer)
      case tokenizer.to_s
      when /\A(?:token_?)?bigram\z/i
        "TokenBigram"
      when /\A(?:token_?)?delimit\z/i
        "TokenDelimit"
      when /\A(?:token_?)?mecab\z/i
        "TokenMecab"
      else
        tokenizer
      end
    end

    def normalize_normalizer(normalizer)
      case normalizer.to_s
      when /\A(?:normalizer_?)?auto\z/i
        "NormalizerAuto"
      else
        normalizer
      end
    end

    class CreateTableMigration
      def initialize(migration, table_name)
        @migration = migration
        @table_name = table_name
      end

      def boolean(column_name, options={})
        @migration.add_column(@table_name, column_name, :bool, options)
      end
      alias_method :bool, :boolean

      def integer(column_name, options={})
        options = options.dup
        bit = options.delete(:bit) || 32
        unsigned = options.delete(:unsigned)
        if unsigned
          type = "uint#{bit}"
        else
          type = "int#{bit}"
        end
        @migration.add_column(@table_name, column_name, type, options)
      end

      def float(column_name, options={})
        @migration.add_column(@table_name, column_name, :float, options)
      end

      def time(column_name, options={})
        @migration.add_column(@table_name, column_name, :time, options)
      end

      def short_text(column_name, options={})
        @migration.add_column(@table_name, column_name, :short_text, options)
      end

      def text(column_name, options={})
        @migration.add_column(@table_name, column_name, :text, options)
      end

      def long_text(column_name, options={})
        @migration.add_column(@table_name, column_name, :long_text, options)
      end

      def geo_point(column_name, options={})
        options = options.dup
        datum = options.delete(:datum) || :wgs84
        case datum
        when :wgs84
          type = "WGS84GeoPoint"
        when :tokyo
          type = "TokyoGeoPoint"
        else
          message = "invalid geodetic datum: "
          message << "available: [:wgs84, :tokyo]: #{datum.inspect}"
          raise ArgumentError, message
        end
        @migration.add_column(@table_name, column_name, type, options)
      end

      def wgs84_geo_point(column_name, options={})
        geo_point(column_name, options.merge(datum: :wgs84))
      end

      def tokyo_geo_point(column_name, options={})
        geo_point(column_name, options.merge(datum: :tokyo))
      end

      def reference(column_name, reference_table_name, options={})
        @migration.add_column(@table_name,
                              column_name,
                              reference_table_name,
                              options)
      end

      def timestamps
        @migration.add_timestamp_columns(@table_name)
      end

      def index(source_table_name, source_column_names, options={})
        options = options.dup
        source_column_names = Array(source_column_names)
        column_name = options.delete(:name)
        column_name ||= [source_table_name, *source_column_names].join("_")
        @migration.add_column(@table_name,
                              column_name,
                              source_table_name,
                              options.merge(:type => :index,
                                            :sources => source_column_names))
      end
    end
  end
end
