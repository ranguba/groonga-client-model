# Copyright (C) 2021  Sutou Kouhei <kou@clear-code.com>
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

class TestMigrationColumn < Test::Unit::TestCase
  include GroongaClientModel::TestHelper
  include TestHelper::Migration

  test("#int8") do
    expected_up_report = <<-REPORT
-- create_table(:posts, {:type=>"TABLE_HASH_KEY", :key_type=>"ShortText"})
   -> 0.0s
-- add_column(:posts, :count, {:flags=>["COLUMN_SCALAR"], :value_type=>"Int8"})
   -> 0.0s
    REPORT
    expected_down_report = <<-REPORT
-- remove_table(:posts)
   -> 0.0s
    REPORT
    expected_dump = <<-DUMP.chomp
table_create posts TABLE_HASH_KEY ShortText
column_create posts count COLUMN_SCALAR Int8
    DUMP
    assert_migrate(expected_up_report,
                   expected_down_report,
                   expected_dump) do |migration|
      migration.instance_eval do
        create_table(:posts,
                     type: :hash,
                     key_type: "ShortText") do |table|
          table.int8(:count)
        end
      end
    end
  end

  test("#int16") do
    expected_up_report = <<-REPORT
-- create_table(:posts, {:type=>"TABLE_HASH_KEY", :key_type=>"ShortText"})
   -> 0.0s
-- add_column(:posts, :count, {:flags=>["COLUMN_SCALAR"], :value_type=>"Int16"})
   -> 0.0s
    REPORT
    expected_down_report = <<-REPORT
-- remove_table(:posts)
   -> 0.0s
    REPORT
    expected_dump = <<-DUMP.chomp
table_create posts TABLE_HASH_KEY ShortText
column_create posts count COLUMN_SCALAR Int16
    DUMP
    assert_migrate(expected_up_report,
                   expected_down_report,
                   expected_dump) do |migration|
      migration.instance_eval do
        create_table(:posts,
                     type: :hash,
                     key_type: "ShortText") do |table|
          table.int16(:count)
        end
      end
    end
  end

  test("#int32") do
    expected_up_report = <<-REPORT
-- create_table(:posts, {:type=>"TABLE_HASH_KEY", :key_type=>"ShortText"})
   -> 0.0s
-- add_column(:posts, :count, {:flags=>["COLUMN_SCALAR"], :value_type=>"Int32"})
   -> 0.0s
    REPORT
    expected_down_report = <<-REPORT
-- remove_table(:posts)
   -> 0.0s
    REPORT
    expected_dump = <<-DUMP.chomp
table_create posts TABLE_HASH_KEY ShortText
column_create posts count COLUMN_SCALAR Int32
    DUMP
    assert_migrate(expected_up_report,
                   expected_down_report,
                   expected_dump) do |migration|
      migration.instance_eval do
        create_table(:posts,
                     type: :hash,
                     key_type: "ShortText") do |table|
          table.int32(:count)
        end
      end
    end
  end

  test("#int64") do
    expected_up_report = <<-REPORT
-- create_table(:posts, {:type=>"TABLE_HASH_KEY", :key_type=>"ShortText"})
   -> 0.0s
-- add_column(:posts, :count, {:flags=>["COLUMN_SCALAR"], :value_type=>"Int64"})
   -> 0.0s
    REPORT
    expected_down_report = <<-REPORT
-- remove_table(:posts)
   -> 0.0s
    REPORT
    expected_dump = <<-DUMP.chomp
table_create posts TABLE_HASH_KEY ShortText
column_create posts count COLUMN_SCALAR Int64
    DUMP
    assert_migrate(expected_up_report,
                   expected_down_report,
                   expected_dump) do |migration|
      migration.instance_eval do
        create_table(:posts,
                     type: :hash,
                     key_type: "ShortText") do |table|
          table.int64(:count)
        end
      end
    end
  end

  test("#uint8") do
    expected_up_report = <<-REPORT
-- create_table(:posts, {:type=>"TABLE_HASH_KEY", :key_type=>"ShortText"})
   -> 0.0s
-- add_column(:posts, :count, {:flags=>["COLUMN_SCALAR"], :value_type=>"UInt8"})
   -> 0.0s
    REPORT
    expected_down_report = <<-REPORT
-- remove_table(:posts)
   -> 0.0s
    REPORT
    expected_dump = <<-DUMP.chomp
table_create posts TABLE_HASH_KEY ShortText
column_create posts count COLUMN_SCALAR UInt8
    DUMP
    assert_migrate(expected_up_report,
                   expected_down_report,
                   expected_dump) do |migration|
      migration.instance_eval do
        create_table(:posts,
                     type: :hash,
                     key_type: "ShortText") do |table|
          table.uint8(:count)
        end
      end
    end
  end

  test("#uint16") do
    expected_up_report = <<-REPORT
-- create_table(:posts, {:type=>"TABLE_HASH_KEY", :key_type=>"ShortText"})
   -> 0.0s
-- add_column(:posts, :count, {:flags=>["COLUMN_SCALAR"], :value_type=>"UInt16"})
   -> 0.0s
    REPORT
    expected_down_report = <<-REPORT
-- remove_table(:posts)
   -> 0.0s
    REPORT
    expected_dump = <<-DUMP.chomp
table_create posts TABLE_HASH_KEY ShortText
column_create posts count COLUMN_SCALAR UInt16
    DUMP
    assert_migrate(expected_up_report,
                   expected_down_report,
                   expected_dump) do |migration|
      migration.instance_eval do
        create_table(:posts,
                     type: :hash,
                     key_type: "ShortText") do |table|
          table.uint16(:count)
        end
      end
    end
  end

  test("#uint32") do
    expected_up_report = <<-REPORT
-- create_table(:posts, {:type=>"TABLE_HASH_KEY", :key_type=>"ShortText"})
   -> 0.0s
-- add_column(:posts, :count, {:flags=>["COLUMN_SCALAR"], :value_type=>"UInt32"})
   -> 0.0s
    REPORT
    expected_down_report = <<-REPORT
-- remove_table(:posts)
   -> 0.0s
    REPORT
    expected_dump = <<-DUMP.chomp
table_create posts TABLE_HASH_KEY ShortText
column_create posts count COLUMN_SCALAR UInt32
    DUMP
    assert_migrate(expected_up_report,
                   expected_down_report,
                   expected_dump) do |migration|
      migration.instance_eval do
        create_table(:posts,
                     type: :hash,
                     key_type: "ShortText") do |table|
          table.uint32(:count)
        end
      end
    end
  end

  test("#uint64") do
    expected_up_report = <<-REPORT
-- create_table(:posts, {:type=>"TABLE_HASH_KEY", :key_type=>"ShortText"})
   -> 0.0s
-- add_column(:posts, :count, {:flags=>["COLUMN_SCALAR"], :value_type=>"UInt64"})
   -> 0.0s
    REPORT
    expected_down_report = <<-REPORT
-- remove_table(:posts)
   -> 0.0s
    REPORT
    expected_dump = <<-DUMP.chomp
table_create posts TABLE_HASH_KEY ShortText
column_create posts count COLUMN_SCALAR UInt64
    DUMP
    assert_migrate(expected_up_report,
                   expected_down_report,
                   expected_dump) do |migration|
      migration.instance_eval do
        create_table(:posts,
                     type: :hash,
                     key_type: "ShortText") do |table|
          table.uint64(:count)
        end
      end
    end
  end
end
