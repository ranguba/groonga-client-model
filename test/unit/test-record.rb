# Copyright (C) 2016  Kouhei Sutou <kou@clear-code.com>
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

class RecordTest < Test::Unit::TestCase
  sub_test_case("#load_values") do
    class LoadValuesRecord < GroongaClientModel::Record
      class << self
        def columns
          GroongaClientModel::Schema::Columns.new({"created_at" => {}})
        end
      end
    end

    setup do
      @record = LoadValuesRecord.new
    end

    def test_date
      @record.created_at = Date.new(2016, 12, 6)
      assert_equal({"created_at" => "2016-12-06 00:00:00"},
                   @record.__send__(:load_values))
    end

    def test_time
      @record.created_at = Time.local(2016, 12, 6, 18, 41, 24, 195422)
      assert_equal({"created_at" => "2016-12-06 18:41:24.195422"},
                   @record.__send__(:load_values))
    end
  end
end
