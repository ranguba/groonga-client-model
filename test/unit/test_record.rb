# Copyright (C) 2016-2017  Kouhei Sutou <kou@clear-code.com>
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

class TestRecord < Test::Unit::TestCase
  Column = Groonga::Client::Response::Schema::Column

  sub_test_case("ActiveModel") do
    class EmptyModel < GroongaClientModel::Record
      class << self
        def columns
          raw_columns = {
            "_id" => Column.new(nil, {}),
          }
          GroongaClientModel::Schema::Columns.new(nil, raw_columns)
        end
      end
    end

    include ActiveModel::Lint::Tests

    setup do
      @model = EmptyModel.new
    end
  end

  sub_test_case("readers") do
    class Memo < GroongaClientModel::Record
      class << self
        def columns
          GroongaClientModel::Schema::Columns.new(nil, "_id" => {})
        end
      end
    end

    setup do
      @memo = Memo.new
    end

    test "#id" do
      @memo._id = 29
      assert_equal(29, @memo.id)
    end
  end

  sub_test_case("validations") do
    sub_test_case("_key presence") do
      class NoKey < GroongaClientModel::Record
        class << self
          def columns
            raw_columns = {
              "_id" => Column.new(nil, {}),
            }
            GroongaClientModel::Schema::Columns.new(nil, raw_columns)
          end
        end
      end

      class HaveKey < GroongaClientModel::Record
        class << self
          def columns
            raw_columns = {
              "_id" => Column.new(nil, {}),
              "_key" => Column.new(nil, {
                                     "name" => "_key",
                                     "value_type" => {
                                       "name" => "ShortText",
                                     },
                                   }),
            }
            GroongaClientModel::Schema::Columns.new(nil, raw_columns)
          end
        end
      end

      test "no key" do
        record = NoKey.new
        assert do
          record.valid?
        end
        assert_equal({}, record.errors.messages)
      end

      test "have key" do
        record = HaveKey.new
        assert do
          not record.save
        end
        assert_equal({
                       :_key => [record.errors.generate_message(:_key, :blank)],
                     },
                     record.errors.messages)
      end
    end
  end
end
