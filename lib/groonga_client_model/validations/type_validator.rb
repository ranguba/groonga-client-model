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
  module Validations
    class TypeValidator < ActiveModel::EachValidator
      def validate_each(record, attribute, value)
        column = record.class.columns[attribute]
        return if column.nil?
        value_type = column["value_type"]
        return if value_type.nil?

        case value_type["name"]
        when "UInt8"
          validate_uint(record, attribute, value, 8)
        when "UInt16"
          validate_uint(record, attribute, value, 16)
        when "UInt32"
          validate_uint(record, attribute, value, 32)
        when "UInt64"
          validate_uint(record, attribute, value, 64)
        when "Int8"
          validate_int(record, attribute, value, 8)
        when "Int16"
          validate_int(record, attribute, value, 16)
        when "Int32"
          validate_int(record, attribute, value, 32)
        when "Int64"
          validate_int(record, attribute, value, 64)
        when "Float"
          validate_float(record, attribute, value)
        when "Time"
          validate_time(record, attribute, value)
        end
      end

      private
      def validate_uint(record, attribute, value, n_bits)
        if value.is_a?(String)
          begin
            value = Integer(value)
          rescue ArgumentError
          end
        end

        case value
        when Numeric
          if value < 0
            record.errors.add(attribute,
                              :not_a_positive_integer,
                              options.merge(inspected_value: value.inspect))
            return
          end
          if value > ((2 ** n_bits) - 1)
            record.errors.add(attribute,
                              :"invalid_uint#{n_bits}",
                              options.merge(inspected_value: value.inspect))
            return
          end
        else
          record.errors.add(attribute,
                            :not_a_positive_integer,
                            options.merge(inspected_value: value.inspect))
        end
      end

      def validate_int(record, attribute, value, n_bits)
        if value.is_a?(String)
          begin
            value = Integer(value)
          rescue ArgumentError
          end
        end

        case value
        when Numeric
          min = -(2 ** (n_bits - 1))
          max = ((2 ** (n_bits - 1)) - 1)
          if value < min or value > max
            record.errors.add(attribute,
                              :"invalid_int#{n_bits}",
                              options.merge(inspected_value: value.inspect))
            return
          end
        else
          record.errors.add(attribute, :not_an_integer)
        end
      end

      def validate_float(record, attribute, value)
        if value.is_a?(String)
          begin
            value = Float(value)
          rescue ArgumentError
          end
        end

        case value
        when Numeric
        else
          record.errors.add(attribute, :not_a_number)
        end
      end

      def validate_time(record, attribute, value)
        if value.is_a?(String)
          begin
            value = Float(value)
          rescue ArgumentError
            begin
              value = Time.strptime(value, "%Y-%m-%d %H:%M:%S.%N")
            rescue ArgumentError
              begin
                value = Time.strptime(value, "%Y-%m-%d %H:%M:%S")
              rescue ArgumentError
              end
            end
          end
        end

        case value
        when Date, Time, Numeric
        else
          record.errors.add(attribute, :not_a_time,
                            options.merge(inspected_value: value.inspect))
        end
      end
    end
  end
end
