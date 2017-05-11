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

class TestMigrationRename < Test::Unit::TestCase
  include GroongaClientModel::TestHelper
  include TestHelper::Migration

  setup do
    open_client do |client|
      client.table_create(name: "posts",
                          flags: "TABLE_HASH_KEY",
                          key_type: "ShortText")
      client.column_create(table: "posts",
                           name: "content",
                           flags: "COLUMN_SCALAR",
                           type: "Text")
      values = [
        {"_key" => "Groonga", "content" => "Very good!"},
        {"_key" => "Ruby",    "content" => "Very exciting!"},
      ]
      client.load(table: "posts",
                  values: values)
    end
  end

  test("#rename_column") do
    expected_up_report = <<-REPORT
-- rename_column(:posts, "content", "new_content")
   -> 0.0s
    REPORT
    expected_down_report = <<-REPORT
-- rename_column(:posts, "new_content", "content")
   -> 0.0s
    REPORT
    expected_dump = <<-DUMP.chomp
table_create posts TABLE_HASH_KEY ShortText
column_create posts new_content COLUMN_SCALAR Text

load --table posts
[
["_key","new_content"],
["Groonga","Very good!"],
["Ruby","Very exciting!"]
]
    DUMP
    assert_migrate(expected_up_report,
                   expected_down_report,
                   expected_dump) do |migration|
      migration.instance_eval do
        rename_column(:posts, "content", "new_content")
      end
    end
  end
end
