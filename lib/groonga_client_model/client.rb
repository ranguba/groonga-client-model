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

module GroongaClientModel
  class Client
    class_attribute :url, instance_accessor: false

    class << self
      def open(&block)
        new.open(&block)
      end
    end

    attr_reader :url
    def initialize(url=nil)
      @url = url || self.class.url || "http://127.0.0.1:10041"
    end

    def open
      Groonga::Client.open(url: @url) do |client|
        client.extend(Notifiable)
        yield(client)
      end
    end

    module Notifiable
      private
      def execute_command(command, &block)
        name = "groonga.groonga_client_model"
        payload = {
          :command => command,
        }
        ActiveSupport::Notifications.instrument(name, payload) do
          super(command, &block)
        end
      end
    end
  end
end
