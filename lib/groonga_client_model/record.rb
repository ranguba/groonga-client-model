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
  class Record
    extend ActiveModel::Naming
    include ActiveModel::Validations
    include ActiveModel::AttributeMethods
    include ActiveModel::AttributeAssignment

    class << self
      def schema
        @@schema ||= Schema.new
      end

      def table_name
        name.to_s.demodulize.underscore.pluralize
      end

      def columns
        schema.tables[table_name].columns
      end

      def define_attributes
        return if defined?(@defined)
        @defined = true
        columns.each do |name, column|
          define_attribute_methods name

          attribute_method_suffix "="
          define_attribute_methods name
        end
      end

      def all
        Client.open do |client|
          response = client.select(table: table_name,
                                   limit: -1)
          response.records.collect do |attributes|
            record = new(attributes)
            record.instance_variable_set(:@new_record, false)
            record
          end
        end
      end

      def find(id)
        Client.open do |client|
          response = client.select(table: table_name,
                                   filter: "_id == #{id}",
                                   limit: 1)
          attributes = response.records.first
          if attributes.nil?
            raise RecordNotFound.new("Record not found: _id: <#{id}>")
          end
          record = new(attributes)
          record.instance_variable_set(:@new_record, false)
          record
        end
      end

      private
      def define_method_attribute(name)
        define_method(name) do
          @attributes[name]
        end
      end

      def define_method_attribute=(name)
        define_method("#{name}=") do |value|
          @attributes[name] = value
        end
      end
    end

    attr_reader :attributes

    def initialize(attributes=nil)
      @attributes = {}
      self.class.define_attributes
      assign_attributes(attributes) if attributes

      @new_record = true
    end

    def save(validate: false)
      if validate
        if valid?
          upsert
        else
          false
        end
      else
        upsert
      end
    end

    def to_model
      self
    end

    def to_key
      if persisted?
        [_id.to_s]
      else
        nil
      end
    end

    def to_param
      if persisted?
        _id.to_s
      else
        nil
      end
    end

    def new_record?
      @new_record
    end

    def persisted?
      not @new_record
    end

    private
    def upsert
      Client.open do |client|
        response = client.load(table: self.class.table_name,
                               values: [attributes])
        unless response.success?
          message = "Failed to save: "
          message << "#{response.error_code}: #{response.error_message}"
          raise RecordNotSaved.new(message, self)
        end
        if response.body.zero?
          message = "Failed to save: #{self.inspect}"
          raise RecordNotSaved.new(message, self)
        end
        @new_record = false
        true
      end
    end
  end
end
