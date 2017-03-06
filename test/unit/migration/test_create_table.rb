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

class TestMigrationCreateTable < Test::Unit::TestCase
  include GroongaClientModel::TestHelper
  include TestHelper::Migration

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

    test("tokenizer") do
      expected_up_report = <<-REPORT
-- create_table(:terms, {:type=>"TABLE_PAT_KEY", :key_type=>"ShortText", :tokenizer=>"TokenBigram"})
   -> 0.0s
      REPORT
      expected_down_report = <<-REPORT
-- remove_table(:terms)
   -> 0.0s
      REPORT
      expected_dump = <<-DUMP.chomp
table_create terms TABLE_PAT_KEY ShortText --default_tokenizer TokenBigram
      DUMP
      assert_migrate(expected_up_report,
                     expected_down_report,
                     expected_dump) do |migration|
        migration.instance_eval do
          create_table(:terms,
                       :type => :patricia_trie,
                       :tokenizer => :bigram)
        end
      end
    end

    test("normalizer") do
      expected_up_report = <<-REPORT
-- create_table(:terms, {:type=>"TABLE_PAT_KEY", :key_type=>"ShortText", :normalizer=>"NormalizerAuto"})
   -> 0.0s
      REPORT
      expected_down_report = <<-REPORT
-- remove_table(:terms)
   -> 0.0s
      REPORT
      expected_dump = <<-DUMP.chomp
table_create terms TABLE_PAT_KEY ShortText --normalizer NormalizerAuto
      DUMP
      assert_migrate(expected_up_report,
                     expected_down_report,
                     expected_dump) do |migration|
        migration.instance_eval do
          create_table(:terms,
                       :type => :patricia_trie,
                       :normalizer => :auto)
        end
      end
    end
  end

  sub_test_case("propose") do
    test("full_text_search") do
      expected_up_report = <<-REPORT
-- create_table(:terms, {:type=>"TABLE_PAT_KEY", :key_type=>"ShortText", :tokenizer=>"TokenBigram", :normalizer=>"NormalizerAuto"})
   -> 0.0s
      REPORT
      expected_down_report = <<-REPORT
-- remove_table(:terms)
   -> 0.0s
      REPORT
      expected_dump = <<-DUMP.chomp
table_create terms TABLE_PAT_KEY ShortText --default_tokenizer TokenBigram --normalizer NormalizerAuto
      DUMP
      assert_migrate(expected_up_report,
                     expected_down_report,
                     expected_dump) do |migration|
        migration.instance_eval do
          create_table(:terms, :propose => :full_text_search)
        end
      end
    end
  end

  sub_test_case("columns") do
    sub_test_case("#boolean") do
      test("default") do
        expected_up_report = <<-REPORT
-- create_table(:posts, {:type=>"TABLE_NO_KEY"})
   -> 0.0s
-- add_column(:posts, :published, {:flags=>["COLUMN_SCALAR"], :value_type=>"Bool"})
   -> 0.0s
        REPORT
        expected_down_report = <<-REPORT
-- remove_table(:posts)
   -> 0.0s
        REPORT
        expected_dump = <<-DUMP.chomp
table_create posts TABLE_NO_KEY
column_create posts published COLUMN_SCALAR Bool
        DUMP
        assert_migrate(expected_up_report,
                       expected_down_report,
                       expected_dump) do |migration|
          migration.instance_eval do
            create_table(:posts) do |table|
              table.boolean(:published)
            end
          end
        end
      end

      test("#bool alias") do
        expected_up_report = <<-REPORT
-- create_table(:posts, {:type=>"TABLE_NO_KEY"})
   -> 0.0s
-- add_column(:posts, :published, {:flags=>["COLUMN_SCALAR"], :value_type=>"Bool"})
   -> 0.0s
        REPORT
        expected_down_report = <<-REPORT
-- remove_table(:posts)
   -> 0.0s
        REPORT
        expected_dump = <<-DUMP.chomp
table_create posts TABLE_NO_KEY
column_create posts published COLUMN_SCALAR Bool
        DUMP
        assert_migrate(expected_up_report,
                       expected_down_report,
                       expected_dump) do |migration|
          migration.instance_eval do
            create_table(:posts) do |table|
              table.bool(:published)
            end
          end
        end
      end
    end

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

    sub_test_case("#index") do
      test("for full text search") do
        expected_up_report = <<-REPORT
-- create_table(:posts, {:type=>"TABLE_NO_KEY"})
   -> 0.0s
-- add_column(:posts, :content, {:flags=>["COLUMN_SCALAR"], :value_type=>"Text"})
   -> 0.0s
-- create_table(:terms, {:type=>"TABLE_PAT_KEY", :key_type=>"ShortText", :tokenizer=>"TokenBigram", :normalizer=>"NormalizerAuto"})
   -> 0.0s
-- add_column(:terms, "posts_content", {:flags=>["COLUMN_INDEX", "WITH_POSITION"], :value_type=>:posts, :sources=>[:content]})
   -> 0.0s
        REPORT
        expected_down_report = <<-REPORT
-- remove_table(:terms)
   -> 0.0s
-- remove_table(:posts)
   -> 0.0s
        REPORT
        expected_dump = <<-DUMP.chomp
table_create posts TABLE_NO_KEY
column_create posts content COLUMN_SCALAR Text

table_create terms TABLE_PAT_KEY ShortText --default_tokenizer TokenBigram --normalizer NormalizerAuto

column_create terms posts_content COLUMN_INDEX|WITH_POSITION posts content
        DUMP
        assert_migrate(expected_up_report,
                       expected_down_report,
                       expected_dump) do |migration|
          migration.instance_eval do
            create_table(:posts) do |table|
              table.text(:content)
            end

            create_table(:terms,
                         :type => :patricia_trie,
                         :tokenizer => :bigram,
                         :normalizer => :auto) do |table|
              table.index(:posts, :content)
            end
          end
        end
      end
    end
  end
end
