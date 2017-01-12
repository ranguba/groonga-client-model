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

require "active_model/railtie"
require "action_controller/railtie"

module GroongaClientModel
  class Railtie < Rails::Railtie
    config.groonga_client_model = ActiveSupport::OrderedOptions.new

    # TODO
    # config.app_generators.orm(:groonga_client_model,
    #                           migration: true,
    #                           timestamps: true)

    config.action_dispatch.rescue_responses.merge!(
      "GroongaClientModel::RecordNotFound" => :not_found,
      "GroongaClientModel::RecordInvalid"  => :unprocessable_entity,
      "GroongaClientModel::RecordNotSaved" => :unprocessable_entity,
    )

    config.eager_load_namespaces << GroongaClientModel

    rake_tasks do
      load "groonga_client_model/railties/groonga.rake"
    end

    initializer "groonga_client_model.logger" do
      ActiveSupport.on_load(:groonga_client_model) do
        self.logger ||= Rails.logger
      end
    end

    initializer "groonga_client_model.log_runtime" do
      require "groonga_client_model/railties/controller_runtime"
      ActiveSupport.on_load(:action_controller) do
        include GroongaClientModel::Railties::ControllerRuntime
      end
    end

    initializer "groonga_client_model.set_configs" do |app|
      ActiveSupport.on_load(:groonga_client_model) do
        app.config.groonga_client_model.each do |key, value|
          send("#{key}=", value)
        end
      end
    end

    initializer "groonga_client_model.initialize_client" do
      ActiveSupport.on_load(:groonga_client_model) do
        config = Rails.application.config_for(:groonga)
        Client.url = config["url"]
      end
    end
  end
end
