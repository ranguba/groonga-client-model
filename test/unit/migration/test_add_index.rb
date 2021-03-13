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

class TestMigrationAddIndex < Test::Unit::TestCase
  include GroongaClientModel::TestHelper
  include TestHelper::Migration

  setup do
    open_client do |client|
      client.table_create(name: "posts",
                          flags: "TABLE_HASH_KEY",
                          key_type: "ShortText")
      client.column_create(table: "posts",
                           name: "title",
                           flags: "COLUMN_SCALAR",
                           type: "ShortText")
      client.column_create(table: "posts",
                           name: "content",
                           flags: "COLUMN_SCALAR",
                           type: "Text")
      client.table_create(name: "terms",
                          flags: "TABLE_PAT_KEY",
                          key_type: "ShortText",
                          default_tokeniezr: "TokenBigram",
                          normalizer: "NormalizerNFKC130")
    end
  end

  test("single column") do
    expected_up_report = <<-REPORT
-- add_column(:terms, "posts_content", {:flags=>["WITH_POSITION", "COLUMN_INDEX"], :value_type=>:posts, :sources=>["content"]})
   -> 0.0s
    REPORT
    expected_down_report = <<-REPORT
-- remove_column(:terms, "posts_content")
   -> 0.0s
    REPORT
    expected_dump = <<-DUMP.chomp
table_create posts TABLE_HASH_KEY ShortText
column_create posts content COLUMN_SCALAR Text
column_create posts title COLUMN_SCALAR ShortText

table_create terms TABLE_PAT_KEY ShortText --normalizer NormalizerNFKC130

column_create terms posts_content COLUMN_INDEX|WITH_POSITION posts content
    DUMP
    assert_migrate(expected_up_report,
                   expected_down_report,
                   expected_dump) do |migration|
      migration.instance_eval do
        add_index(:terms, :posts, ["content"], flags: ["WITH_POSITION"])
      end
    end
  end

  test("multiple columns") do
    expected_up_report = <<-REPORT
-- add_column(:terms, "posts_title_content", {:flags=>["WITH_POSITION", "COLUMN_INDEX", "WITH_SECTION"], :value_type=>:posts, :sources=>["title", "content"]})
   -> 0.0s
    REPORT
    expected_down_report = <<-REPORT
-- remove_column(:terms, "posts_title_content")
   -> 0.0s
    REPORT
    expected_dump = <<-DUMP.chomp
table_create posts TABLE_HASH_KEY ShortText
column_create posts content COLUMN_SCALAR Text
column_create posts title COLUMN_SCALAR ShortText

table_create terms TABLE_PAT_KEY ShortText --normalizer NormalizerNFKC130

column_create terms posts_title_content COLUMN_INDEX|WITH_SECTION|WITH_POSITION posts title,content
    DUMP
    assert_migrate(expected_up_report,
                   expected_down_report,
                   expected_dump) do |migration|
      migration.instance_eval do
        add_index(:terms, :posts, ["title", "content"], flags: ["WITH_POSITION"])
      end
    end
  end
end
