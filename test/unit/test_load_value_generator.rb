# Copyright (C) 2016-2021  Sutou Kouhei <kou@clear-code.com>
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

class TestLoadValueGenerator < Test::Unit::TestCase
  class Memo < GroongaClientModel::Record
    class << self
      def columns
        TestHelper::Columns.build("tag" => {
                                    "value_type" => {
                                      "name" => "Tag",
                                    },
                                  },
                                  "tags" => {
                                    "value_type" => {
                                      "name" => "Tag",
                                    },
                                  },
                                  "created_at" => {
                                    "value_type" => {
                                      "name" => "Time",
                                    },
                                  })
      end
    end
  end

  class Tag < GroongaClientModel::Record
    class << self
      def columns
        TestHelper::Columns.build("_key" => {
                                    "value_type" => {
                                      "name" => "ShortText",
                                    },
                                  })
      end
    end
  end

  setup do
    @memo = Memo.new
    @generator = GroongaClientModel::LoadValueGenerator.new(@memo)
  end

  test "Date" do
    @memo.created_at = Date.new(2016, 12, 6)
    assert_equal({"created_at" => "2016-12-06 00:00:00"},
                 @generator.generate)
  end

  test "Time" do
    @memo.created_at = Time.local(2016, 12, 6, 18, 41, 24, 195422)
    assert_equal({"created_at" => "2016-12-06 18:41:24.195422"},
                 @generator.generate)
  end

  test "GroongaClientModel::Record" do
    tag = Tag.new(_key: "important")
    @memo.tag = tag
    assert_equal({"tag" => "important"},
                 @generator.generate)
  end

  test "Array" do
    tags = [
      Tag.new(_key: "important"),
      Tag.new(_key: "groonga"),
    ]
    @memo.tags = tags
    assert_equal({"tags" => ["important", "groonga"]},
                 @generator.generate)
  end

  test "_id and _key" do
    tag = Tag.new(_id: 10, _key: "important")
    generator = GroongaClientModel::LoadValueGenerator.new(tag)
    assert_equal({"_key" => "important"},
                 generator.generate)
  end
end
