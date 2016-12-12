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
      @modelized_records ||= super.collect do |raw_record|
        record = @model_class.new(raw_record)
        record.instance_variable_set(:@new_record, false)
        record
      end
    end
  end
end
