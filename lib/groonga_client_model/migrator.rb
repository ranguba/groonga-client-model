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

    def initialize(search_paths, target_version)
      @output = nil
      @search_paths = Array(search_paths)
      @target_version = target_version
      ensure_versions
      @current_version = @versions.last || 0
    end

    def migrate
      each do |definition|
        Client.open do |client|
          migration = definition.create_migration(client)
          migration.output = @output
          report(definition) do
            if forward?
              migration.up
              add_version(client, definition.version)
            else
              migration.down
              delete_version(client, definition.version)
            end
          end
        end
      end
    end

    def each
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
      sorted_definitions = definitions.sort_by(&:version)

      if forward?
        sorted_definitions.each do |definition|
          yield(definition) if definition.version > @current_version
        end
      else
        sorted_definitions.reverse_each do |definition|
          yield(definition) if definition.version <= @current_version
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

    def ensure_versions
      Client.open do |client|
        table_name = version_table_name
        exist = client.object_exist(name: table_name).body
        if exist
          @versions = client.request(:select).
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
          @versions = []
        end
      end
    end

    def forward?
      @target_version.nil? or
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
