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

require "groonga/command/parser"

module GroongaClientModel
  class SchemaLoader
    class << self
      def default_path
        "db/schema.grn"
      end
    end

    def initialize(schema)
      @schema = schema
    end

    def load
      Client.open do |client|
        parser = Groonga::Command::Parser.new
        parser.on_command do |command|
          client.execute(command)
        end
        @schema.each_line do |line|
          parser << line
        end
        parser.finish
      end
    end
  end
end
