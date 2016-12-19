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
  module Modelize
    def model_class=(model_class)
      @model_class = model_class
    end

    # For Kaminari
    def entry_name(options={})
      model_name = @model_class.model_name
      if options[:count] == 1
        default = model_name.human
      else
        default = model_name.human.pluralize
      end
      model_name.human(options.reverse_merge(default: default))
    end

    def records
      @modelized_records ||= build_records(super)
    end

    private
    def build_records(raw_records)
      columns = @model_class.columns
      raw_records.collect do |raw_record|
        attributes, dynamic_attributes = build_attributes(columns, raw_record)
        record = @model_class.new(attributes)
        record.assign_dynamic_attributes(dynamic_attributes)
        record
      end
    end

    def build_attributes(columns, raw_record)
      attributes = {}
      dynamic_attributes = {}
      raw_record.each do |name, value|
        primary_name, sub_name = name.split(".", 2)
        if sub_name.nil?
          if columns.exist?(primary_name)
            if attributes.key?(primary_name)
              value = attributes[primary_name].merge("_key" => value)
            end
            attributes[primary_name] = value
          else
            dynamic_attributes[primary_name] = value
          end
        else
          if columns.exist?(primary_name)
            if attributes.key?(primary_name)
              unless attributes[primary_name].is_a?(Hash)
                attributes[primary_name] = {
                  "_key" => attributes[primary_name],
                }
              end
            else
              attributes[primary_name] = {}
            end
            attributes[primary_name][sub_name] = value
          else
            dynamic_attributes[name] = value
          end
        end
      end
      [attributes, dynamic_attributes]
    end
  end
end
