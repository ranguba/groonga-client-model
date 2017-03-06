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

class TestRecordTimestamps < Test::Unit::TestCase
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
    timestamp = Timestamp.create
    saved_timestamp = Timestamp.find(timestamp)
    assert do
      saved_timestamp.created_at > now
    end
  end

  test("created_on") do
    now = Time.now
    timestamp = Timestamp.create
    saved_timestamp = Timestamp.find(timestamp)
    assert do
      saved_timestamp.created_on > now
    end
  end

  test("updated_at") do
    timestamp = Timestamp.create
    saved_timestamp = Timestamp.find(timestamp)
    created_at = saved_timestamp.created_at
    saved_timestamp.save
    updated_timestamp = Timestamp.find(timestamp)
    updated_timestamp.save
    assert do
      saved_timestamp.updated_at > created_at
    end
  end

  test("updated_on") do
    timestamp = Timestamp.create
    saved_timestamp = Timestamp.find(timestamp)
    created_on = saved_timestamp.created_on
    saved_timestamp.save
    updated_timestamp = Timestamp.find(timestamp)
    updated_timestamp.save
    assert do
      saved_timestamp.updated_on > created_on
    end
  end
end
