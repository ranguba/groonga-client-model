# Copyright (C) 2016-2017  Kouhei Sutou <kou@clear-code.com>
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

module GroongaClientModel
  class Schema
    def initialize
      @raw = GroongaClientModel::Client.open do |client|
        response = client.schema
        unless response.success?
          message = "failed to retrieve schema: "
          message << "#{response.return_code}:#{response.error_message}"
          raise Error, message
        end
        response
      end
    end

    def tables
      Tables.new(@raw, @raw.tables)
    end

    class Tables
      def initialize(raw_schema, raw_tables)
        @raw_schema = raw_schema
        @raw_tables = raw_tables
      end

      def [](name)
        name = name.to_s if name.is_a?(Symbol)
        raw_table = @raw_tables[name]
        raise Error, "table doesn't exist: <#{name.inspect}>" if raw_table.nil?
        Table.new(@raw_schema, raw_table)
      end

      def exist?(name)
        @raw_tables.key?(name)
      end
    end

    class Table
      def initialize(raw_schema, raw_table)
        @raw_schema = raw_schema
        @raw_table = raw_table
      end

      def name
        @raw_table.name
      end

      def columns
        raw_columns = {}
        raw_columns["_id"] = create_pseudo_column("_id", {"name" => "UInt32"})
        key_type = @raw_table.key_type
        if key_type
          raw_columns["_key"] = create_pseudo_column("_key", key_type)
        end
        Columns.new(@raw_schema, @raw_table.columns.merge(raw_columns))
      end

      private
      def create_pseudo_column(name, value_type)
        raw_column = {
          "name" => name,
          "indexes" => [],
          "value_type" => value_type,
        }
        Groonga::Client::Response::Schema::Column.new(@raw_schema, raw_column)
      end
    end

    class Columns
      include Enumerable

      def initialize(raw_schema, raw_columns)
        @raw_schema = raw_schema
        @raw_columns = raw_columns
      end

      def exist?(name)
        @raw_columns.key?(normalize_name(name))
      end

      def names
        @raw_columns.keys
      end

      def [](name)
        @raw_columns[normalize_name(name)]
      end

      def each
        @raw_columns.each do |name, column|
          yield(name, column)
        end
      end

      private
      def normalize_name(name)
        name.to_s
      end
    end
  end
end
