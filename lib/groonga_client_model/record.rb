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
    include ActiveModel::AttributeAssignment
    include ActiveModel::AttributeMethods
    include ActiveModel::Conversion
    include ActiveModel::Translation
    include ActiveModel::Validations

    class << self
      def i18n_scope
        :groonga_client_model
      end

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
        attribute_method_suffix("=")
        define_attribute_methods(*columns.names)
      end

      def count
        select.limit(0).output_columns("_id").response.n_hits
      end

      def all
        select.limit(-1)
      end

      def find(id)
        record = select.filter("_id == %{id}", id: id).limit(1).first
        if record.nil?
          raise RecordNotFound.new("Record not found: _id: <#{id}>")
        end
        record
      end

      def first
        select.sort_keys("_id").limit(1).first
      end

      def last
        select.sort_keys("-_id").limit(1).first
      end

      def select
        full_text_searchable_column_names = []
        columns.each do |name, column|
          if column.have_full_text_search_index?
            full_text_searchable_column_names << name
          end
        end
        model_class = self
        model_class_module = Module.new do
          define_method :model_class do
            model_class
          end
        end
        extensions = [
          ClientOpener,
          Modelizable,
          model_class_module,
        ]
        Groonga::Client::Request::Select.new(table_name, extensions).
          match_columns(full_text_searchable_column_names)
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
      @destroyed = false
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

    def save!(validate: false)
      unless save(validate: validate)
        message = "Failed to save the record"
        raise RecordNotSaved.new(message, self)
      end
    end

    def destroy
      if persisted?
        Client.open do |client|
          table = self.class.schema.tables[self.class.table_name]
          response = client.delete(table: table.name,
                                   filter: "_id == #{_id}")
          unless response.success?
            message = "Failed to delete the record: "
            message << "#{response.return_code}: #{response.error_message}"
            raise Error.new(message, self)
          end
        end
      end
      @destroyed = true
      freeze
    end

    def update(attributes)
      assign_attributes(attributes)
      save
    end

    def id
      _id
    end

    def new_record?
      @new_record
    end

    def destroyed?
      @destroyed
    end

    def persisted?
      return false if @new_record
      return false if @destroyed
      true
    end

    def assign_dynamic_attributes(dynamic_attributes)
      return if dynamic_attributes.blank?

      dynamic_attributes.each do |name, value|
        assign_dynamic_attribute(name, value)
      end
    end

    def assign_dynamic_attribute(name, value)
      if respond_to?(name)
        singleton_class.__send__(:undef_method, name)
      end
      singleton_class.__send__(:define_method, name) do
        value
      end
    end

    private
    def upsert
      Client.open do |client|
        table = self.class.schema.tables[self.class.table_name]
        load_value_generator = LoadValueGenerator.new(self)
        value = load_value_generator.generate
        response = client.load(table: table.name,
                               values: [value],
                               output_ids: "yes",
                               command_version: "3")
        unless response.success?
          message = "Failed to save: "
          message << "#{response.return_code}: #{response.error_message}"
          raise RecordNotSaved.new(message, self)
        end
        if response.n_loaded_records.zero?
          message = "Failed to save: #{value.inspect}"
          raise RecordNotSaved.new(message, self)
        end
        if @new_record
          id = response.loaded_ids.first
          if id.nil?
            select_request = self.class.select.limit(1).output_columns("_id")
            if @attributes.key?("_key")
              select_request = select_request.filter("_key == %{key}",
                                                     key: _key)
            else
              # TODO: may return not newly added record
              select_request = select_request.sort_keys("-_id")
            end
            id = select_request.first._id
          end
          self._id = id
        end
        @new_record = false
        true
      end
    end
  end
end
