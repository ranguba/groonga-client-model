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

module GroongaClientModel
  class LogSubscriber < ActiveSupport::LogSubscriber
    if respond_to?(:thread_cattr_accessor)
      thread_cattr_accessor :runtime, instance_accessor: false
    else
      # For ActiveSupport < 5
      class << self
        def runtime
          Thread.current["groonga_client_model.log_subscriber.runtime"]
        end

        def runtime=(value)
          Thread.current["groonga_client_model.log_subscriber.runtime"] = value
        end
      end
    end

    class << self
      def reset_runtime
        self.runtime = 0.0
      end

      def measure
        before_runtime = runtime
        yield
        runtime - before_runtime
      end
    end

    def groonga(event)
      self.class.runtime = (self.class.runtime || 0) + event.duration

      debug do
        command = event.payload[:command]

        title = color("#{command.command_name} (#{event.duration.round(1)}ms)",
                      title_color(command),
                      bold: true)
        formatted_command = color(command.to_command_format,
                                  command_color(command),
                                  bold: true)
        "  #{title}  #{formatted_command}"
      end
    end

    private
    def title_color(command)
      if command.command_name == "select"
        MAGENTA
      else
        CYAN
      end
    end

    def command_color(command)
      case command.command_name
      when "select"
        BLUE
      when "load"
        GREEN
      when "delete"
        RED
      else
        MAGENTA
      end
    end

    def logger
      GroongaClientModel.logger
    end

    attach_to :groonga_client_model
  end
end
