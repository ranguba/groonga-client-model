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

class TestMigrator < Test::Unit::TestCase
  include GroongaClientModel::TestHelper

  def create_migrator
    path = File.expand_path("fixtures/migrate", __dir__)
    migrator = GroongaClientModel::Migrator.new(path)
    migrator.output = StringIO.new
    migrator
  end

  sub_test_case("#target_version=") do
    sub_test_case("exist") do
      test("forward") do
        migrator = create_migrator
        migrator.target_version = 20170303115054
        assert_equal([
                       20170301061420,
                       20170303115054,
                     ],
                     migrator.each.collect(&:version))
      end

      test("backward") do
      create_migrator.migrate

        migrator = create_migrator
        migrator.target_version = 20170303115054
        assert_equal([
                       20170303115135,
                     ],
                     migrator.each.collect(&:version))
      end
    end

    sub_test_case("not exist") do
      test("forward") do
        migrator = create_migrator
        migrator.target_version = 9999_99_99_999999
        assert_equal([
                       20170301061420,
                       20170303115054,
                       20170303115135,
                     ],
                     migrator.each.collect(&:version))
      end

      test("backward") do
      create_migrator.migrate

        migrator = create_migrator
        migrator.target_version = -1
        assert_equal([
                       20170303115135,
                       20170303115054,
                       20170301061420,
                     ],
                     migrator.each.collect(&:version))
      end
    end
  end

  sub_test_case("#step=") do
    test("positive") do
      migrator = create_migrator
      migrator.step = 2
      assert_equal([
                     20170301061420,
                     20170303115054,
                   ],
                   migrator.each.collect(&:version))
    end

    test("too large") do
      migrator = create_migrator
      migrator.step = 4
      assert_equal([
                     20170301061420,
                     20170303115054,
                     20170303115135,
                   ],
                   migrator.each.collect(&:version))
    end

    test("negative") do
      create_migrator.migrate

      migrator = create_migrator
      migrator.step = -2
      assert_equal([
                     20170303115135,
                     20170303115054,
                   ],
                   migrator.each.collect(&:version))
    end

    test("too small") do
      create_migrator.migrate

      migrator = create_migrator
      migrator.step = -4
      assert_equal([
                     20170303115135,
                     20170303115054,
                     20170301061420,
                   ],
                   migrator.each.collect(&:version))
    end
  end
end
