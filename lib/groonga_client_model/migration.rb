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

  class Migration
    attr_accessor :output

    def initialize(client)
      @client = client
      @output = nil
      @reverting = false
    end

    def up
      change
    end

    def down
      revert do
        change
      end
    end

    def revert
      @reverting = true
      begin
        yield
      ensure
        @reverting = false
      end
    end

    def create_table(name, type: nil, key_type: nil)
      return remove_table_raw(name) if @reverting

      type = normalize_table_type(type || :array)
      if type != "TABLE_NO_KEY" and key_type.nil?
        key_type ||= "ShortText"
      end
      key_type = normalize_type(key_type)
      options = {type: type}
      options[:key_type] = key_type if key_type
      report(__method__, [name, options]) do
        @client.request(:table_create).
          parameter(:name, name).
          flags_parameter(:flags, [type]).
          parameter(:key_type, key_type).
          response
      end

      yield(CreateTableMigration.new(self, name)) if block_given?
    end

    def remove_table(name)
      if @reverting
        raise IrreversibleMigrationError, "can't revert remove_table(#{name})"
      end

      remove_table_raw(name)
    end

    def add_column(table_name, column_name, value_type, options={})
      return remove_column_raw(name) if @reverting

      value_type = normalize_type(value_type)
      flags = []
      flags << normalize_column_type(options[:type] || :scalar)
      arguments = [
        table_name,
        column_name,
        flags: flags,
        value_type: value_type,
      ]
      report(__method__, arguments) do
        @client.request(:column_create).
          parameter(:table, table_name).
          parameter(:name, column_name).
          flags_parameter(:flags, flags).
          parameter(:type, value_type).
          values_parameter(:source, options[:source]).
          response
      end
    end

    def remove_column(table_name, column_name)
      if @reverting
        message = "can't revert remove_column(#{table_name}, #{column_name})"
        raise IrreversibleMigrationError, message
      end

      remove_column_raw(table_name, column_name)
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

    def remove_table_raw(name)
      report(:remove_table, [name]) do
        @client.request(:table_remove).
          parameter(:name, name).
          response
      end
    end

    def remove_column_raw(table_name, column_name)
      report(:remove_column, [table_name, column_name]) do
        @client.request(:column_remove).
          parameter(:table_name, table_name).
          parameter(:name, column_name).
          response
      end
    end

    class CreateTableMigration
      def initialize(migration, table_name)
        @migration = migration
        @table_name = table_name
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
    end
  end
end
