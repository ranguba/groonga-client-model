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

module GroongaClientModel
  class MigrationError < Error
  end

  class IrreversibleMigrationError < MigrationError
  end

  class Migration
    def initialize(client)
      @client = client
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
      report(__method__, [name, type: type, key_type: key_type]) do
        @client.request(:table_create).
          parameter(:name, name).
          flags_parameter(:flags, [type]).
          parameter(:key_type, key_type).
          response
      end
    end

    def remove_table(name)
      if @reverting
        raise IrreversibleMigrationError, "can't revert remove_table(#{name})"
      end

      remove_table_raw(name)
    end

    private
    def report(method_name, arguments)
      argument_list = arguments.collect(&:inspect).join(", ")
      puts("-- #{method_name}(#{argument_list})")
      time = Benchmark.measure do
        response = yield
      end
      puts("   -> %.4fs" % time.real)
    end

    def normalize_table_type(type)
      case type.to_s
      when "array", /\A(?:TABLE_)?NO_KEY\z/i
        "TABLE_NO_KEY"
      when "hash", /\A(?:TABLE_)?HASH_KEY\z/i
        "TABLE_HASH_KEY"
      when "pat", "patricia_trie", /\A(?:TABLE_)?PAT_KEY\z/i
        "TABLE_PAT_KEY"
      when "dat", "double_array_trie", /\A(?:TABLE_)?DAT_KEY\z/i
        "TABLE_DAT_KEY"
      else
        type
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
  end
end
