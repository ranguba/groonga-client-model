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

    if config.app_generators.orm.empty?
      config.app_generators.orm(:groonga_client_model)
    end

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
        config_dir = Rails.application.paths["config"].existent.first
        config_path = Pathname(config_dir) + "groonga.yml"
        unless config_path.exist?
          config_path.open("w") do |config_file|
            config_file.puts(<<-CONFIG)
default: &default
  url: http://127.0.0.1:10041/
  # url: https://127.0.0.1:10041/
  # protocol: http
  # host: 127.0.0.1
  # port: 10041
  # user: alice
  # password: secret
  read_timeout: -1
  # read_timeout: 3
  backend: synchronous

development:
  <<: *default

test:
  <<: *default
  url: http://127.0.0.1:20041/

production:
  <<: *default
  # url: http://production.example.com:10041/
  read_timeout: 10
            CONFIG
          end
        end
        config = Rails.application.config_for(:groonga)
        Client.url = config["url"]
      end
    end
  end
end
