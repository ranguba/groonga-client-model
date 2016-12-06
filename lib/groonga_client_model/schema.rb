# Copyright (C) 2016  Kouhei Sutou <kou@clear-code.com>
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
      Tables.new(@raw.tables)
    end

    class Tables
      def initialize(raw)
        @raw = raw
      end

      def [](name)
        name = name.to_s if name.is_a?(Symbol)
        raw_table = @raw[name]
        raise Error, "table doesn't exist: <#{name.inspect}>" if raw_table.nil?
        Table.new(raw_table)
      end

      def exist?(name)
        @raw.key?(name)
      end
    end

    class Table
      def initialize(raw)
        @raw = raw
      end

      def name
        @raw.name
      end

      def columns
        raw_columns = @raw.columns.merge("_id" => {"name" => "_id"})
        if @raw.key_type
          raw_columns = raw_columns.merge("_key" => {"name" => "_key"})
        end
        Columns.new(raw_columns)
      end
    end

    class Columns
      include Enumerable

      def initialize(raw)
        @raw = raw
      end

      def names
        @raw.keys
      end

      def each
        @raw.each do |name, column|
          yield(name, column)
        end
      end
    end
  end
end
