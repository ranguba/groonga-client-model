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

require "active_support/testing/parallelization"

require "groonga_client_model/test/fixture"

module GroongaClientModel
  module TestHelper
    include Test::Fixture

    extend ActiveSupport::Concern

    parallel_test = false
    ActiveSupport::Testing::Parallelization.after_fork_hook do
      parallel_test = true
    end

    included do
      setup do
        setup_groonga(parallel_test: parallel_test)
      end

      teardown do
        teardown_groonga
      end
    end
  end
end
