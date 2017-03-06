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

require "rails/generators/named_base"
require "rails/generators/migration"

require "groonga-client-model"
require "groonga_client_model/migration"
require "groonga_client_model/migrator"

module GroongaClientModel
  module Generators
    class MigrationGenerator < Rails::Generators::NamedBase
      include Rails::Generators::Migration

      class << self
        def next_migration_number(dirname)
          next_migration_number = current_migration_number(dirname) + 1
          Migrator.next_migration_number(next_migration_number)
        end
      end

      source_root File.join(__dir__, "migration", "templates")

      argument :attributes,
               type: :array,
               default: [],
               banner: "name:type name:type"

      class_option :table_type,
                   type: :string,
                   desc: "The table type (array, hash_table, patricia_trie or double_array_trie)"
      class_option :table_propose,
                   type: :string,
                   desc: "The table propose (full_text_search)"
      class_option :timestamps,
                   type: :boolean,
                   desc: "Whether creating columns for timestamps or not"

      def create_migration_file
        IllegalMigrationNameError.validate(file_name)
        decide_template(file_name)
        migration_template(@migration_template,
                           File.join("db/groonga/migrate", "#{file_name}.rb"))
      end

      private
      def decide_template(output_file_name)
        @migration_template = "migration.rb"
        @migration_action = nil
        @key_type = nil
        case output_file_name
        when /\A(add|remove)_.*_(?:to|from)_(.*)\z/
          @migration_action = $1
          @table_name = normalize_table_name($2)
        when /\Acreate_(.+)\z/
          @table_name = normalize_table_name($1)
          @migration_template = "create_table_migration.rb"
          attributes.each do |attribute|
            if attribute.name == "_key"
              @key_type = attribute.type
              break
            end
          end
        end
      end

      def normalize_table_name(name)
        name.pluralize
      end

      def create_table_options
        table_type = @options[:table_type]
        table_propose = @options[:table_propose]
        options_text = ""
        if table_type
          options_text = ", type: :#{table_type}"
          options_text << ", key_type: :#{@key_type}" if @key_type
        end
        options_text << ", propose: :#{table_propose}" if table_propose
        options_text
      end

      def target_attributes
        attributes.reject do |attribute|
          attribute.name == "_key"
        end
      end
    end
  end
end
