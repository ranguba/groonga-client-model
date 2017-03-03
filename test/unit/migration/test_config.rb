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

class TestMigrationConfig < Test::Unit::TestCase
  include GroongaClientModel::TestHelper
  include TestHelper::Migration

  test("#set_config") do
    expected_up_report = <<-REPORT
-- set_config("alias.column", "aliases.real_name")
   -> 0.0s
    REPORT
    expected_down_report = nil
    expected_dump = <<-DUMP.chomp
config_set alias.column aliases.real_name
    DUMP
    assert_migrate(expected_up_report,
                   expected_down_report,
                   expected_dump) do |migration|
      migration.instance_eval do
        set_config("alias.column", "aliases.real_name")
      end
    end
  end

  test("#delete_config") do
    open_client do |client|
      client.request(:config_set).
        parameter(:key, "alias.column").
        parameter(:value, "aliases.real_name").
        response
    end

    expected_up_report = <<-REPORT
-- delete_config("alias.column")
   -> 0.0s
    REPORT
    expected_down_report = nil
    expected_dump = <<-DUMP.chomp
    DUMP
    assert_migrate(expected_up_report,
                   expected_down_report,
                   expected_dump) do |migration|
      migration.instance_eval do
        delete_config("alias.column")
      end
    end
  end
end
