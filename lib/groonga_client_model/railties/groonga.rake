# -*- ruby -*-
#
# Copyright (C) 2016-2017  Kouhei Sutou <kou@clear-code.com>
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

require "groonga_client_model/migrator"

namespace :groonga do
  namespace :config do
    desc "Load config/groonga.rb"
    task load: [:environment] do
      config = Rails.application.config_for(:groonga)
      GroongaClientModel::Client.url = config["url"]
    end
  end

  namespace :schema do
    desc "Loads db/schema.grn into the Groonga database"
    task load: ["config:load"] do
      schema_loader = GroongaClientModel::SchemaLoader.new(Rails.root)
      schema_loader.load
    end
  end

  desc "Migrate the Groonga database"
  task migrate: ["config:load"] do
    Rails.application.paths["db/groonga/migrate"] ||=
      GroongaClientModel::Migrator.default_search_path
    migration_paths = Rails.application.paths["db/groonga/migrate"].to_a
    version = nil
    version = Integer(ENV["VERSION"]) if ENV["VERSION"]
    migrator = GroongaClientModel::Migrator.new(migration_paths, version)
    migrator.migrate
  end
end
