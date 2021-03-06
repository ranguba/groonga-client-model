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
    def assert_migrate_add_column(column_name,
                                  groonga_type,
                                  options={})
      expected_up_report = <<-REPORT
-- create_table(:posts, {:type=>"TABLE_NO_KEY"})
   -> 0.0s
-- add_column(:posts, :#{column_name}, {:flags=>["COLUMN_SCALAR"], :value_type=>#{groonga_type.inspect}})
   -> 0.0s
      REPORT
      expected_down_report = <<-REPORT
-- remove_table(:posts)
   -> 0.0s
      REPORT
      expected_dump = <<-DUMP.chomp
table_create posts TABLE_NO_KEY
column_create posts #{column_name} COLUMN_SCALAR #{groonga_type}
      DUMP
      assert_migrate(expected_up_report,
                     expected_down_report,
                     expected_dump) do |migration|
        migration.instance_eval do
          create_table(:posts) do |table|
            yield(table)
          end
        end
      end
    end

    sub_test_case("#boolean") do
      test("default") do
        assert_migrate_add_column(:published, "Bool") do |table|
          table.boolean(:published)
        end
      end

      test("alias: #bool") do
        assert_migrate_add_column(:published, "Bool") do |table|
          table.bool(:published)
        end
      end
    end

    sub_test_case("#integer") do
      test("default") do
        assert_migrate_add_column(:score, "Int32") do |table|
          table.integer(:score)
        end
      end

      test("bit: 8") do
        assert_migrate_add_column(:score, "Int8") do |table|
          table.integer(:score, bit: 8)
        end
      end

      test("bit: 16") do
        assert_migrate_add_column(:score, "Int16") do |table|
          table.integer(:score, bit: 16)
        end
      end

      test("bit: 32") do
        assert_migrate_add_column(:score, "Int32") do |table|
          table.integer(:score, bit: 32)
        end
      end

      test("bit: 64") do
        assert_migrate_add_column(:score, "Int64") do |table|
          table.integer(:score, bit: 64)
        end
      end

      test("bit: 8, unsigned: true") do
        assert_migrate_add_column(:score, "UInt8") do |table|
          table.integer(:score, bit: 8, unsigned: true)
        end
      end

      test("bit: 16, unsigned: true") do
        assert_migrate_add_column(:score, "UInt16") do |table|
          table.integer(:score, bit: 16, unsigned: true)
        end
      end

      test("bit: 32, unsigned: true") do
        assert_migrate_add_column(:score, "UInt32") do |table|
          table.integer(:score, bit: 32, unsigned: true)
        end
      end

      test("bit: 64, unsigned: true") do
        assert_migrate_add_column(:score, "UInt64") do |table|
          table.integer(:score, bit: 64, unsigned: true)
        end
      end
    end

    sub_test_case("#float") do
      test("default") do
        assert_migrate_add_column(:score, "Float") do |table|
          table.float(:score)
        end
      end
    end

    sub_test_case("#time") do
      test("default") do
        assert_migrate_add_column(:published_at, "Time") do |table|
          table.time(:published_at)
        end
      end
    end

    sub_test_case("#short_text") do
      test("default") do
        assert_migrate_add_column(:title, "ShortText") do |table|
          table.short_text(:title)
        end
      end
    end

    sub_test_case("#text") do
      test("default") do
        assert_migrate_add_column(:content, "Text") do |table|
          table.text(:content)
        end
      end
    end

    sub_test_case("#long_text") do
      test("default") do
        assert_migrate_add_column(:content, "LongText") do |table|
          table.long_text(:content)
        end
      end
    end

    sub_test_case("#geo_point") do
      test("default") do
        assert_migrate_add_column(:location, "WGS84GeoPoint") do |table|
          table.geo_point(:location)
        end
      end

      test("datum: :wgs84") do
        assert_migrate_add_column(:location, "WGS84GeoPoint") do |table|
          table.geo_point(:location, datum: :wgs84)
        end
      end

      test("datum: :tokyo") do
        assert_migrate_add_column(:location, "TokyoGeoPoint") do |table|
          table.geo_point(:location, datum: :tokyo)
        end
      end

      test("alias: #wgs84_geo_point") do
        assert_migrate_add_column(:location, "WGS84GeoPoint") do |table|
          table.wgs84_geo_point(:location)
        end
      end

      test("alias: #tokyo_geo_point") do
        assert_migrate_add_column(:location, "TokyoGeoPoint") do |table|
          table.tokyo_geo_point(:location)
        end
      end
    end

    sub_test_case("#reference") do
      def assert_migrate_add_reference_column(column_name,
                                              reference_table_name,
                                              options={})
        open_client do |client|
          client.table_create(name: reference_table_name,
                              flags: "TABLE_HASH_KEY",
                              key_type: "ShortText")
        end

        flags = []
        case options[:type]
        when :vector
          flags << "COLUMN_VECTOR"
        else
          flags << "COLUMN_SCALAR"
        end

        expected_up_report = <<-REPORT
-- create_table(:posts, {:type=>"TABLE_NO_KEY"})
   -> 0.0s
-- add_column(:posts, :#{column_name}, {:flags=>#{flags.inspect}, :value_type=>#{reference_table_name.inspect}})
   -> 0.0s
        REPORT
        expected_down_report = <<-REPORT
-- remove_table(:posts)
   -> 0.0s
        REPORT
        expected_dump = <<-DUMP.chomp
table_create posts TABLE_NO_KEY

table_create #{reference_table_name} TABLE_HASH_KEY ShortText

column_create posts #{column_name} #{flags.join("|")} #{reference_table_name}
        DUMP
        assert_migrate(expected_up_report,
                       expected_down_report,
                       expected_dump) do |migration|
          migration.instance_eval do
            create_table(:posts) do |table|
              yield(table)
            end
          end
        end
      end

      test("default") do
        assert_migrate_add_reference_column(:user, :users) do |table|
          table.reference(:user, :users)
        end
      end

      test("type: :vector") do
        assert_migrate_add_reference_column(:user,
                                            :users,
                                            type: :vector) do |table|
          table.reference(:user, :users, type: :vector)
        end
      end
    end

    sub_test_case("#timestamps") do
      test("default") do
        expected_up_report = <<-REPORT
-- create_table(:posts, {:type=>"TABLE_NO_KEY"})
   -> 0.0s
-- add_column(:posts, :created_at, {:flags=>["COLUMN_SCALAR"], :value_type=>"Time"})
   -> 0.0s
-- add_column(:posts, :updated_at, {:flags=>["COLUMN_SCALAR"], :value_type=>"Time"})
   -> 0.0s
        REPORT
        expected_down_report = <<-REPORT
-- remove_table(:posts)
   -> 0.0s
        REPORT
        expected_dump = <<-DUMP.chomp
table_create posts TABLE_NO_KEY
column_create posts created_at COLUMN_SCALAR Time
column_create posts updated_at COLUMN_SCALAR Time
        DUMP
        assert_migrate(expected_up_report,
                       expected_down_report,
                       expected_dump) do |migration|
          migration.instance_eval do
            create_table(:posts) do |table|
              table.timestamps
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

      test("multi sources") do
        expected_up_report = <<-REPORT
-- create_table(:posts, {:type=>"TABLE_NO_KEY"})
   -> 0.0s
-- add_column(:posts, :title, {:flags=>["COLUMN_SCALAR"], :value_type=>"ShortText"})
   -> 0.0s
-- add_column(:posts, :content, {:flags=>["COLUMN_SCALAR"], :value_type=>"Text"})
   -> 0.0s
-- create_table(:terms, {:type=>"TABLE_PAT_KEY", :key_type=>"ShortText", :tokenizer=>"TokenBigram", :normalizer=>"NormalizerAuto"})
   -> 0.0s
-- add_column(:terms, "posts_title_content", {:flags=>["COLUMN_INDEX", "WITH_POSITION", "WITH_SECTION"], :value_type=>:posts, :sources=>[:title, :content]})
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
column_create posts title COLUMN_SCALAR ShortText

table_create terms TABLE_PAT_KEY ShortText --default_tokenizer TokenBigram --normalizer NormalizerAuto

column_create terms posts_title_content COLUMN_INDEX|WITH_SECTION|WITH_POSITION posts title,content
        DUMP
        assert_migrate(expected_up_report,
                       expected_down_report,
                       expected_dump) do |migration|
          migration.instance_eval do
            create_table(:posts) do |table|
              table.short_text(:title)
              table.text(:content)
            end

            create_table(:terms,
                         :propose => :full_text_search) do |table|
              table.index(:posts, [:title, :content])
            end
          end
        end
      end

      test("custom name") do
        expected_up_report = <<-REPORT
-- create_table(:posts, {:type=>"TABLE_NO_KEY"})
   -> 0.0s
-- add_column(:posts, :content, {:flags=>["COLUMN_SCALAR"], :value_type=>"Text"})
   -> 0.0s
-- create_table(:terms, {:type=>"TABLE_PAT_KEY", :key_type=>"ShortText", :tokenizer=>"TokenBigram", :normalizer=>"NormalizerAuto"})
   -> 0.0s
-- add_column(:terms, :posts, {:flags=>["COLUMN_INDEX", "WITH_POSITION"], :value_type=>:posts, :sources=>[:content]})
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

column_create terms posts COLUMN_INDEX|WITH_POSITION posts content
        DUMP
        assert_migrate(expected_up_report,
                       expected_down_report,
                       expected_dump) do |migration|
          migration.instance_eval do
            create_table(:posts) do |table|
              table.text(:content)
            end

            create_table(:terms,
                         :propose => :full_text_search) do |table|
              table.index(:posts, [:content], name: :posts)
            end
          end
        end
      end
    end
  end
end
