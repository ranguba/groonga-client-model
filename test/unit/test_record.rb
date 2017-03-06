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

      class Int8Key < Key
        class << self
          def key_type
            "Int8"
          end
        end
      end

      class Int16Key < Key
        class << self
          def key_type
            "Int16"
          end
        end
      end

      class Int32Key < Key
        class << self
          def key_type
            "Int32"
          end
        end
      end

      class Int64Key < Key
        class << self
          def key_type
            "Int64"
          end
        end
      end

      class FloatKey < Key
        class << self
          def key_type
            "Float"
          end
        end
      end

      class TimeKey < Key
        class << self
          def key_type
            "Time"
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
            assert_invalid(UInt8Key, "String", :not_a_positive_integer)
          end

          test("too large") do
            assert_invalid(UInt8Key, 2 ** 8, :invalid_uint8)
          end
        end

        sub_test_case("UInt16") do
          test("invalid") do
            assert_invalid(UInt16Key, "String", :not_a_positive_integer)
          end

          test("too large") do
            assert_invalid(UInt16Key, 2 ** 16, :invalid_uint16)
          end
        end

        sub_test_case("UInt32") do
          test("invalid") do
            assert_invalid(UInt32Key, "String", :not_a_positive_integer)
          end

          test("too large") do
            assert_invalid(UInt32Key, 2 ** 32, :invalid_uint32)
          end
        end

        sub_test_case("UInt64") do
          test("invalid") do
            assert_invalid(UInt64Key, "String", :not_a_positive_integer)
          end

          test("too large") do
            assert_invalid(UInt64Key, 2 ** 64, :invalid_uint64)
          end
        end

        sub_test_case("Int8") do
          test("invalid") do
            assert_invalid(Int8Key, "String", :not_an_integer)
          end

          test("too small") do
            assert_invalid(Int8Key, -(2 ** 7) - 1, :invalid_int8)
          end

          test("too large") do
            assert_invalid(Int8Key, 2 ** 7, :invalid_int8)
          end
        end

        sub_test_case("Int16") do
          test("invalid") do
            assert_invalid(Int16Key, "String", :not_an_integer)
          end

          test("too small") do
            assert_invalid(Int16Key, -(2 ** 15) - 1, :invalid_int16)
          end

          test("too large") do
            assert_invalid(Int16Key, 2 ** 15, :invalid_int16)
          end
        end

        sub_test_case("Int32") do
          test("invalid") do
            assert_invalid(Int32Key, "String", :not_an_integer)
          end

          test("too small") do
            assert_invalid(Int32Key, -(2 ** 31) - 1, :invalid_int32)
          end

          test("too large") do
            assert_invalid(Int32Key, 2 ** 31, :invalid_int32)
          end
        end

        sub_test_case("Int64") do
          test("invalid") do
            assert_invalid(Int64Key, "String", :not_an_integer)
          end

          test("too small") do
            assert_invalid(Int64Key, -(2 ** 63) - 1, :invalid_int64)
          end

          test("too large") do
            assert_invalid(Int64Key, 2 ** 63, :invalid_int64)
          end
        end

        sub_test_case("Float") do
          test("invalid") do
            assert_invalid(FloatKey, "String", :not_a_number)
          end
        end

        sub_test_case("Time") do
          test("invalid") do
            assert_invalid(TimeKey, "String", :not_a_time)
          end
        end
      end
    end
  end

  sub_test_case("timestamps") do
    include GroongaClientModel::TestHelper

    setup do
      schema = <<-SCHEMA
table_create timestamps TABLE_NO_KEY
column_create timestamps created_at COLUMN_SCALAR Time
column_create timestamps created_on COLUMN_SCALAR Time
column_create timestamps updated_at COLUMN_SCALAR Time
column_create timestamps updated_on COLUMN_SCALAR Time
      SCHEMA
      schema_loader = GroongaClientModel::SchemaLoader.new(schema)
      schema_loader.load
    end

    class Timestamp < GroongaClientModel::Record
    end

    test("created_at") do
      now = Time.now
      timestamp = Timestamp.new
      timestamp.save
      saved_timestamp = Timestamp.find(timestamp._id)
      assert do
        saved_timestamp.created_at > now
      end
    end

    test("created_on") do
      now = Time.now
      timestamp = Timestamp.new
      timestamp.save
      saved_timestamp = Timestamp.find(timestamp._id)
      assert do
        saved_timestamp.created_on > now
      end
    end

    test("updated_at") do
      timestamp = Timestamp.new
      timestamp.save
      saved_timestamp = Timestamp.find(timestamp._id)
      created_at = saved_timestamp.created_at
      saved_timestamp.save
      updated_timestamp = Timestamp.find(timestamp._id)
      updated_timestamp.save
      assert do
        saved_timestamp.updated_at > created_at
      end
    end

    test("updated_on") do
      timestamp = Timestamp.new
      timestamp.save
      saved_timestamp = Timestamp.find(timestamp._id)
      created_on = saved_timestamp.created_on
      saved_timestamp.save
      updated_timestamp = Timestamp.find(timestamp._id)
      updated_timestamp.save
      assert do
        saved_timestamp.updated_on > created_on
      end
    end
  end
end
