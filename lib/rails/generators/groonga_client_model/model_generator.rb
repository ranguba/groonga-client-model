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
require "rails/generators/active_model"
require "groonga-client-model"

module GroongaClientModel
  module Generators
    class ModelGenerator < Rails::Generators::NamedBase
      source_root File.join(__dir__, "model", "templates")

      argument :attributes,
               type: :array,
               default: [],
               banner: "field[:type][:index] field[:type][:index]"

      check_class_collision

      class_option :parent,
                   type: :string,
                   desc: "The parent class for the generated model"

      hook_for :test_framework

      def create_model_file
        generate_application_groonga_record
        template("model.rb",
                 File.join("app/models", class_path, "#{file_name}.rb"))
      end

      private
      def generate_application_groonga_record
        if behavior == :invoke and !application_groonga_record_exist?
          template("application_groonga_record.rb",
                   application_groonga_record_file_name)
        end
      end

      def parent_class_name
        options[:parent] || "ApplicationGroongaRecord"
      end

      def application_groonga_record_exist?
        in_root do
          File.exist?(application_groonga_record_file_name)
        end
      end

      def application_groonga_record_file_name
        "app/models/application_groonga_record.rb"
        end
    end
  end
end
