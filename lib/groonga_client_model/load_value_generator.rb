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

require "date"

module GroongaClientModel
  class LoadValueGenerator
    def initialize(record)
      @record = record
    end

    def generate
      load_value = {}
      @record.attributes.each do |name, value|
        load_value[name] = format_value(value)
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
      else
        value = value
      end
    end
  end
end
