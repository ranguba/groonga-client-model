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

  def migrate(direction)
    migration_class = Class.new(GroongaClientModel::Migration) do |klass|
      define_method(:change) do
        yield(self)
      end
    end
    output = StringIO.new
    open_client do |client|
      migration = migration_class.new(client)
      migration.output = output
      migration.up
    end
    normalize_report(output.string)
  end

  def normalize_report(report)
    report.gsub(/[0-9]+\.[0-9]+s/, "0.0s")
  end

  def dump
    open_client do |client|
      client.dump.body
    end
  end

  sub_test_case("#create_table") do
    test("default") do
      report = migrate(:up) do |migration|
        migration.instance_eval do
          create_table(:posts)
        end
      end
      assert_equal(<<-REPORT, report)
-- create_table(:posts, {:type=>"TABLE_NO_KEY", :key_type=>nil})
   -> 0.0s
      REPORT
      assert_equal(<<-DUMP.chomp, dump)
table_create posts TABLE_NO_KEY
      DUMP
    end
  end
end
