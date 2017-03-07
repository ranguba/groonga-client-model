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

class TestMigrationExist < Test::Unit::TestCase
  include GroongaClientModel::TestHelper
  include TestHelper::Migration

  test("table") do
    expected_up_report = <<-REPORT
-- create_table(:posts, {:type=>"TABLE_NO_KEY"})
   -> 0.0s
-- add_column(:posts, :title, {:flags=>["COLUMN_SCALAR"], :value_type=>"ShortText"})
   -> 0.0s
    REPORT
    expected_down_report = <<-REPORT
-- remove_table(:posts)
   -> 0.0s
    REPORT
    expected_dump = <<-DUMP.chomp
table_create posts TABLE_NO_KEY
column_create posts title COLUMN_SCALAR ShortText
    DUMP
    assert_migrate(expected_up_report,
                   expected_down_report,
                   expected_dump) do |migration|
      migration.instance_eval do
        create_table(:posts)
        unless reverting?
          add_column(:posts, :title, :short_text) if exist?(:posts)
        end
      end
    end
  end
end
