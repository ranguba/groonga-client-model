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

require "groonga_client_model/migration"

class TestMigration < Test::Unit::TestCase
  include GroongaClientModel::TestHelper

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

    down_output = StringIO.new
    open_client do |client|
      migration = migration_class.new(client)
      migration.output = down_output
      migration.down
    end
    assert_equal(expected_down_report, normalize_report(down_output.string))

    assert_equal("", dump)
  end

  sub_test_case("#create_table") do
    test("default") do
      expected_up_report = <<-REPORT
-- create_table(:posts, {:type=>"TABLE_NO_KEY"})
   -> 0.0s
      REPORT
      expected_down_report = <<-REPORT
-- remove_table(:posts)
   -> 0.0s
      REPORT
      expected_dump = <<-DUMP.chomp
table_create posts TABLE_NO_KEY
      DUMP
      assert_migrate(expected_up_report,
                     expected_down_report,
                     expected_dump) do |migration|
        migration.instance_eval do
          create_table(:posts)
        end
      end
    end

    sub_test_case(":type => :patricia_trie") do
      test("default") do
        expected_up_report = <<-REPORT
-- create_table(:terms, {:type=>"TABLE_PAT_KEY", :key_type=>"ShortText"})
   -> 0.0s
        REPORT
        expected_down_report = <<-REPORT
-- remove_table(:terms)
   -> 0.0s
        REPORT
        expected_dump = <<-DUMP.chomp
table_create terms TABLE_PAT_KEY ShortText
      DUMP
        assert_migrate(expected_up_report,
                       expected_down_report,
                       expected_dump) do |migration|
          migration.instance_eval do
            create_table(:terms, :type => :patricia_trie)
          end
        end
      end
    end

    sub_test_case("columns") do
      sub_test_case("#short_text") do
        test("default") do
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
              create_table(:posts) do |table|
                table.short_text(:title)
              end
            end
          end
        end
      end

      sub_test_case("#text") do
        test("default") do
          expected_up_report = <<-REPORT
-- create_table(:posts, {:type=>"TABLE_NO_KEY"})
   -> 0.0s
-- add_column(:posts, :content, {:flags=>["COLUMN_SCALAR"], :value_type=>"Text"})
   -> 0.0s
          REPORT
          expected_down_report = <<-REPORT
-- remove_table(:posts)
   -> 0.0s
          REPORT
          expected_dump = <<-DUMP.chomp
table_create posts TABLE_NO_KEY
column_create posts content COLUMN_SCALAR Text
          DUMP
          assert_migrate(expected_up_report,
                         expected_down_report,
                         expected_dump) do |migration|
            migration.instance_eval do
              create_table(:posts) do |table|
                table.text(:content)
              end
            end
          end
        end
      end

      sub_test_case("#long_text") do
        test("default") do
          expected_up_report = <<-REPORT
-- create_table(:posts, {:type=>"TABLE_NO_KEY"})
   -> 0.0s
-- add_column(:posts, :content, {:flags=>["COLUMN_SCALAR"], :value_type=>"LongText"})
   -> 0.0s
          REPORT
          expected_down_report = <<-REPORT
-- remove_table(:posts)
   -> 0.0s
          REPORT
          expected_dump = <<-DUMP.chomp
table_create posts TABLE_NO_KEY
column_create posts content COLUMN_SCALAR LongText
          DUMP
          assert_migrate(expected_up_report,
                         expected_down_report,
                         expected_dump) do |migration|
            migration.instance_eval do
              create_table(:posts) do |table|
                table.long_text(:content)
              end
            end
          end
        end
      end
    end
  end
end
