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

require "stringio"

require "test-unit"

require "groonga-client-model"
require "groonga_client_model/test_helper"
require "groonga_client_model/migration"

GroongaClientModel::Client.url = "http://127.0.0.1:20041"

module TestHelper
  module Migration
    def open_client(&block)
      GroongaClientModel::Client.open(&block)
    end

    def normalize_report(report)
      report.gsub(/[0-9]+\.[0-9]+s/, "0.0s")
    end

    def dump
      open_client do |client|
        client.dump.body
      end
    end

    def assert_migrate(expected_up_report,
                       expected_down_report,
                       expected_dump)
      migration_class = Class.new(GroongaClientModel::Migration) do |klass|
        define_method(:change) do
          yield(self)
        end
      end

      up_output = StringIO.new
      open_client do |client|
        migration = migration_class.new(client)
        migration.output = up_output
        migration.up
      end
      assert_equal(expected_up_report, normalize_report(up_output.string))

      assert_equal(expected_dump, dump)

      if expected_down_report
        down_output = StringIO.new
        open_client do |client|
          migration = migration_class.new(client)
          migration.output = down_output
          migration.down
        end
        assert_equal(expected_down_report, normalize_report(down_output.string))
        assert_equal("", dump)
      else
        open_client do |client|
          migration = migration_class.new(client)
          assert_raise(GroongaClientModel::IrreversibleMigrationError) do
            migration.down
          end
        end
        assert_equal(expected_dump, dump)
      end

    end
  end
end
