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

require "groonga/client/test-helper"

module GroongaClientModel
  module TestHelper
    extend ActiveSupport::Concern

    included do
      include Groonga::Client::TestHelper

      setup do
        return if @groonga_server_runner.using_running_server?

        if defined?(Rails)
          base_dir = Rails.root
        else
          base_dir = Pathname.pwd
        end
        schema_grn = base_dir + "db" + "schema.grn"
        return unless schema_grn.exist?

        Client.open do |client|
          parser = Groonga::Command::Parser.new
          parser.on_command do |command|
            client.execute(command)
          end
          schema_grn.open do |schema|
            schema.each_line do |line|
              parser << line
            end
          end
          parser.finish
        end
      end
    end
  end
end
