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

class TestMigrationLoad < Test::Unit::TestCase
  include GroongaClientModel::TestHelper
  include TestHelper::Migration

  def assert_migrate_load(values, expected_values_dump)
    expected_up_report = <<-REPORT
-- create_table(:posts, {:type=>"TABLE_HASH_KEY", :key_type=>"ShortText"})
   -> 0.0s
-- add_column(:posts, :content, {:flags=>["COLUMN_SCALAR"], :value_type=>"Text"})
   -> 0.0s
-- load(:posts)
   -> 0.0s
    REPORT
    expected_down_report = nil
    expected_dump = <<-DUMP.chomp
table_create posts TABLE_HASH_KEY ShortText
column_create posts content COLUMN_SCALAR Text

load --table posts
[
["_key","content"],
#{expected_values_dump}
]
    DUMP
    assert_migrate(expected_up_report,
                   expected_down_report,
                   expected_dump) do |migration|
      migration.instance_eval do
        create_table(:posts,
                     :type => :hash_table,
                     :key_type => :short_text) do |t|
          t.text(:content)
        end
        load(:posts, values)
      end
    end
  end

  test("Hash") do
    assert_migrate_load({"_key" => "Groonga", "content" => "Very good!"},
                        <<-DUMP.chomp)
["Groonga","Very good!"]
    DUMP
  end

  test("Array") do
    assert_migrate_load([
                          {"_key" => "Groonga", "content" => "Very good!"},
                          {"_key" => "Ruby",    "content" => "Very exciting!"},
                        ],
                        <<-DUMP.chomp)
["Groonga","Very good!"],
["Ruby","Very exciting!"]
    DUMP
  end

  test("JSON") do
    assert_migrate_load([
                          {"_key" => "Groonga", "content" => "Very good!"},
                          {"_key" => "Ruby",    "content" => "Very exciting!"},
                        ].to_json,
                        <<-DUMP.chomp)
["Groonga","Very good!"],
["Ruby","Very exciting!"]
    DUMP
  end
end
