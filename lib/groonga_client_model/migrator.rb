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

require "groonga_client_model/migration"

module GroongaClientModel
  class Migrator
    class << self
      def next_migration_number(number)
        [Time.now.utc.strftime("%Y%m%d%H%M%S"), "%.14d" % number].max
      end

      def default_search_path
        "db/groonga/migrate"
      end
    end

    attr_accessor :output
    attr_reader :current_version

    def initialize(search_paths)
      @output = nil
      @search_paths = Array(search_paths)
      ensure_versions
      ensure_loaded_versions
      @current_version = @loaded_versions.last
      @target_version = nil
    end

    def target_version=(version)
      @target_version = version
    end

    def step=(step)
      if @current_version.nil?
        index = step - 1
      else
        index = @versions.index(@current_version)
        index += step
      end
      if index < 0
        version = 0
      else
        version = @versions[index]
      end
      self.target_version = version
    end

    def migrate
      is_forward = forward?
      each do |definition|
        Client.open do |client|
          migration = definition.create_migration(client)
          migration.output = @output
          report(definition) do
            if is_forward
              migration.up
              add_version(client, definition.version)
              @current_version = definition.version
            else
              migration.down
              delete_version(client, definition.version)
              previous_version_index = @versions.index(definition.version) - 1
              if previous_version_index < 0
                @current_version = nil
              else
                @current_version = @versions[previous_version_index]
              end
            end
          end
        end
      end
    end

    def each
      return to_enum(:each) unless block_given?

      current_version = @current_version || 0
      if forward?
        sorted_definitions.each do |definition|
          next if definition.version <= current_version
          next if @target_version and definition.version > @target_version
          yield(definition)
        end
      else
        sorted_definitions.reverse_each do |definition|
          next if definition.version > current_version
          next if @target_version and definition.version <= @target_version
          yield(definition)
        end
      end
    end

    private
    def puts(*args)
      if @output
        @output.puts(*args)
      else
        super
      end
    end

    def version_table_name
      "schema_versions"
    end

    def collect_definitions
      paths = []
      @search_paths.each do |search_path|
        paths |= Dir.glob("#{search_path}/**/[0-9]*_*.rb").collect do |path|
          File.expand_path(path)
        end
      end
      definitions = []
      paths.each do |path|
        definition = Definition.new(path)
        definitions << definition if definition.valid?
      end
      definitions
    end

    def sorted_definitions
      @sorted_definitions ||= collect_definitions.sort_by(&:version)
    end

    def ensure_versions
      @versions = sorted_definitions.collect(&:version)
    end

    def ensure_loaded_versions
      Client.open do |client|
        table_name = version_table_name
        exist = client.object_exist(name: table_name).body
        if exist
          @loaded_versions = client.request(:select).
            parameter(:table, table_name).
            sort_keys([:_key]).
            limit(-1).
            output_columns(["_key"]).
            response.
            records.
            collect(&:_key)
        else
          client.request(:table_create).
            parameter(:name, table_name).
            flags_parameter(:flags, ["TABLE_PAT_KEY"]).
            parameter(:key_type, "UInt64").
            response
          @loaded_versions = []
        end
      end
    end

    def forward?
      @target_version.nil? or
        @current_version.nil? or
        (@target_version > @current_version)
    end

    def add_version(client, version)
      client.request(:load).
        parameter(:table, version_table_name).
        parameter(:values, [{"_key" => version}].to_json).
        response
    end

    def delete_version(client, version)
      client.request(:delete).
        parameter(:table, version_table_name).
        parameter(:key, version).
        response
    end

    def report(definition)
      version = definition.version
      name = definition.name
      if forward?
        action = "forward"
      else
        action = "rollback"
      end
      mark("#{version} #{name}: #{action}")
      time = Benchmark.measure do
        yield
      end
      mark("%s %s: %.4fs" % [version, name, time.real])
      puts
    end

    def mark(text)
      pre = "=="
      max_width = 79
      post_length = [0, max_width - pre.length - 1 - text.length - 1].max
      post = "=" * post_length
      puts("#{pre} #{text} #{post}")
    end

    class Definition
      attr_reader :version
      attr_reader :name
      def initialize(path)
        @path = path
        parse_path
      end

      def valid?
        @version and @name and File.exist?(@path)
      end

      def create_migration(client)
        require(@path)
        @name.camelize.constantize.new(client)
      end

      private
      def parse_path
        if /\A([0-9]+)_([_a-z0-9]+)\.rb\z/ =~ File.basename(@path)
          @version = $1.to_i
          @name = $2
        else
          @version = nil
          @name = nil
        end
      end
    end
  end
end
