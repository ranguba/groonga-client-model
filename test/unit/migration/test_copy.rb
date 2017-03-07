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

class TestMigrationCopy < Test::Unit::TestCase
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
      client.table_create(name: "entries",
                          flags: "TABLE_PAT_KEY",
                          key_type: "ShortText")
      client.column_create(table: "entries",
                           name: "content",
                           flags: "COLUMN_SCALAR",
                           type: "LongText")
      values = [
        {"_key" => "Groonga", "content" => "Very good!"},
        {"_key" => "Ruby",    "content" => "Very exciting!"},
      ]
      client.load(table: "posts",
                  values: values)
    end
  end

  test("#copy_table") do
    expected_up_report = <<-REPORT
-- copy_table(:posts, :entries)
   -> 0.0s
    REPORT
    expected_down_report = nil
    expected_dump = <<-DUMP.chomp
table_create entries TABLE_PAT_KEY ShortText
column_create entries content COLUMN_SCALAR LongText

table_create posts TABLE_HASH_KEY ShortText
column_create posts content COLUMN_SCALAR Text

load --table entries
[
["_key","content"],
["Groonga",""],
["Ruby",""]
]

load --table posts
[
["_key","content"],
["Groonga","Very good!"],
["Ruby","Very exciting!"]
]
    DUMP
    assert_migrate(expected_up_report,
                   expected_down_report,
                   expected_dump) do |migration|
      migration.instance_eval do
        copy_table(:posts, :entries)
      end
    end
  end
end
