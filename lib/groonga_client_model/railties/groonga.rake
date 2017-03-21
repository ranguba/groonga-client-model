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
    schema_path = GroongaClientModel::SchemaLoader.default_path
    desc "Loads #{schema_path} into the Groonga database"
    task load: ["config:load"] do
      full_schema_path = Rails.root + schema_path
      schema_loader = GroongaClientModel::SchemaLoader.new(full_schema_path)
      schema_loader.load
    end
  end

  namespace :migrate do
    task setup: ["config:load"] do
      Rails.application.paths["db/groonga/migrate"] ||=
        GroongaClientModel::Migrator.default_search_path
    end

    desc "Rollbacks the Groonga database one version and re-migrates"
    task redo: ["setup"] do
      migration_paths = Rails.application.paths["db/groonga/migrate"].to_a
      migrator = GroongaClientModel::Migrator.new(migration_paths)
      current_version = migrator.current_version
      if ENV["VERSION"]
        migrator.target_version = Integer(ENV["VERSION"])
        migrator.migrate
        migrator.target_version = current_version
        migrator.migrate
      elsif current_version
        if ENV["STEP"]
          step = Integer(ENV["STEP"])
        else
          step = 1
        end
        migrator.step = -step
        migrator.migrate
        migrator.target_version = current_version
        migrator.migrate
      end
    end

    desc "Rolls the Groonga database back to the previous version"
    task rollback: ["setup"] do
      migration_paths = Rails.application.paths["db/groonga/migrate"].to_a
      migrator = GroongaClientModel::Migrator.new(migration_paths)
      if ENV["STEP"]
        step = Integer(ENV["STEP"])
      else
        step = 1
      end
      migrator.step = -step
      migrator.migrate
    end
  end

  desc "Migrates the Groonga database"
  task migrate: ["migrate:setup"] do
    migration_paths = Rails.application.paths["db/groonga/migrate"].to_a
    migrator = GroongaClientModel::Migrator.new(migration_paths)
    migrator.target_version = Integer(ENV["VERSION"]) if ENV["VERSION"]
    migrator.migrate
  end
end
