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
    include AttributeAssignment
    include ActiveModel::AttributeMethods
    include ActiveModel::Callbacks
    include ActiveModel::Conversion
    include ActiveModel::Dirty
    include ActiveModel::Translation
    include ActiveModel::Validations

    class << self
      def i18n_scope
        :groonga_client_model
      end

      def schema
        @@schema ||= Schema.new
      end

      def clear_cache
        @@schema = nil
      end

      def table_name
        name.to_s.demodulize.underscore.pluralize
      end

      def columns
        schema.tables[table_name].columns
      end

      def have_key?
        columns.exist?("_key")
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

      def create(attributes=nil)
        if attributes.is_a?(Array)
          attributes.collect do |attrs|
            create(attrs)
          end
        else
          record = new(attributes)
          record.save
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
          if value.is_a?(Hash)
            value = build_sub_record(name, value)
          end
          unless @attributes[name] == value
            attribute_will_change!(name)
          end
          @attributes[name] = value
        end
      end
    end

    define_model_callbacks :save, :create, :update, :destroy

    attr_reader :attributes

    validates :_key, presence: true, if: ->(record) {record.class.have_key?}

    def initialize(attributes=nil)
      @attributes = {}
      self.class.define_attributes
      assign_attributes(attributes) if attributes

      if @attributes["_id"]
        @new_record = false
        clear_changes_information
      else
        @new_record = true
      end
      @destroyed = false
    end

    def save(validate: true)
      run_callbacks(:save) do
        save_raw(validate: validate)
      end
    end

    def save!(validate: true)
      unless save(validate: validate)
        message = "Failed to save the record"
        raise RecordNotSaved.new(message, self)
      end
    end

    def destroy
      run_callbacks(:destroy) do
        destroy_raw
      end
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
    def save_raw(validate: true)
      if validate
        if valid?
          upsert(validate: true)
        else
          false
        end
      else
        upsert(validate: false)
      end
    end

    def destroy_raw
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

    def upsert(validate: true)
      if new_record?
        run_callbacks(:create) do
          upsert_raw(validate: validate)
        end
      else
        run_callbacks(:update) do
          upsert_raw(validate: validate)
        end
      end
    end

    def upsert_raw(validate: true)
      return false unless upsert_sub_records(validate: validate)

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
        changes_applied
        true
      end
    end

    def upsert_sub_records(validate: true)
      attributes.each do |name, value|
        return false unless upsert_sub_record(value, validate)
      end
      true
    end

    def upsert_sub_record(sub_record, validate)
      case sub_record
      when Record
        if sub_record.changed?
          sub_record.save(validate: validate)
        else
          true
        end
      when Array
        sub_record.each do |sub_element|
          unless upsert_sub_record(sub_element, validate)
            return false
          end
        end
        true
      else
        true
      end
    end

    def build_sub_record(name, value)
      column = self.class.columns[name]
      return value unless column

      return value unless column.value_type.type == "reference"

      class_name = name.classify
      begin
        if self.class.const_defined?(class_name)
          sub_record_class = self.class.const_get(class_name)
        else
          sub_record_class = class_name.constantize
        end
      rescue NameError
        return value
      end

      is_vector = (column.type == "vector")
      if is_vector
        sub_record_values = []
        value.each do |sub_name, sub_values|
          sub_values.each_with_index do |sub_value, i|
            sub_record_value = (sub_record_values[i] ||= {})
            sub_record_value[sub_name] = sub_value
          end
        end
        sub_record_values.collect do |sub_record_value|
          sub_record_class.new(sub_record_value)
        end
      else
        return nil if value["_key"].blank?
        sub_record_class.new(value)
      end
    end
  end
end
