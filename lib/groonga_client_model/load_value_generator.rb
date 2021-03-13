# Copyright (C) 2016-2021  Sutou Kouhei <kou@clear-code.com>
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

require "date"

module GroongaClientModel
  class LoadValueGenerator
    def initialize(record)
      @record = record
    end

    def generate
      load_value = {}
      @record.attributes.each do |name, value|
        next if value.nil?
        load_value[name] = format_value(value)
      end
      if load_value.key?("_id") and load_value.key?("_key")
        load_value.delete("_id")
      end
      load_value
    end

    private
    def format_value(value)
      case value
      when Date
        value.strftime("%Y-%m-%d 00:00:00")
      when Time
        value.strftime("%Y-%m-%d %H:%M:%S.%6N")
      when Record
        format_value(value._key)
      when Array
        value.collect do |sub_value|
          format_value(sub_value)
        end
      else
        value
      end
    end
  end
end
