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
    sub_test_case("_key") do
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

      class Key < GroongaClientModel::Record
        class << self
          def columns
            raw_columns = {
              "_id" => Column.new(nil, {}),
              "_key" => Column.new(nil, {
                                     "name" => "_key",
                                     "value_type" => {
                                       "name" => key_type,
                                     },
                                   }),
            }
            GroongaClientModel::Schema::Columns.new(nil, raw_columns)
          end
        end
      end

      class ShortTextKey < Key
        class << self
          def key_type
            "ShortText"
          end
        end
      end

      class UInt8Key < Key
        class << self
          def key_type
            "UInt8"
          end
        end
      end

      class UInt16Key < Key
        class << self
          def key_type
            "UInt16"
          end
        end
      end

      class UInt32Key < Key
        class << self
          def key_type
            "UInt32"
          end
        end
      end

      class UInt64Key < Key
        class << self
          def key_type
            "UInt64"
          end
        end
      end

      sub_test_case("presence") do
        test "no key" do
          record = NoKey.new
          assert do
            record.valid?
          end
          assert_equal({}, record.errors.messages)
        end

        test "missing key" do
          record = ShortTextKey.new
          assert do
            not record.valid?
          end
          message = record.errors.generate_message(:_key, :blank)
          assert_equal({
                         :_key => [message],
                       },
                       record.errors.messages)
        end

        test "blank key" do
          record = UInt32Key.new(_key: "")
          assert do
            not record.valid?
          end
          message = record.errors.generate_message(:_key, :blank)
          assert_equal({
                         :_key => [message],
                       },
                       record.errors.messages)
        end

        test "have key" do
          record = ShortTextKey.new(_key: "String")
          assert do
            record.valid?
          end
          assert_equal({},
                       record.errors.messages)
        end
      end

      sub_test_case("type") do
        def assert_invalid(klass, key, message_key)
          record = klass.new(_key: key)
          assert do
            not record.valid?
          end
          options = {
            inspected_value: key.inspect
          }
          message = record.errors.generate_message(:_key, message_key, options)
          assert_equal({
                         :_key => [message],
                       },
                       record.errors.messages)
        end

        sub_test_case("UInt8") do
          test("invalid") do
            assert_invalid(UInt8Key, "String", :uint)
          end

          test("too large") do
            assert_invalid(UInt8Key, 2 ** 8, :uint8)
          end
        end

        sub_test_case("UInt16") do
          test("invalid") do
            assert_invalid(UInt16Key, "String", :uint)
          end

          test("too large") do
            assert_invalid(UInt16Key, 2 ** 16, :uint16)
          end
        end

        sub_test_case("UInt32") do
          test("invalid") do
            assert_invalid(UInt32Key, "String", :uint)
          end

          test("too large") do
            assert_invalid(UInt32Key, 2 ** 32, :uint32)
          end
        end

        sub_test_case("UInt64") do
          test("invalid") do
            assert_invalid(UInt64Key, "String", :uint)
          end

          test("too large") do
            assert_invalid(UInt64Key, 2 ** 64, :uint64)
          end
        end
      end
    end
  end
end
