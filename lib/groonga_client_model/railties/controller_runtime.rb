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

require "groonga_client_model/log_subscriber"

module GroongaClientModel
  module Railties
    module ControllerRuntime
      extend ActiveSupport::Concern

      attr_internal :groonga_runtime

      def process_action(action, *args)
        GroongaClientModel::LogSubscriber.reset_runtime
        super
      end

      def cleanup_view_runtime
        total_runtime = nil
        groonga_runtime_in_view = GroongaClientModel::LogSubscriber.measure do
          total_runtime = super
        end
        total_runtime - groonga_runtime_in_view
      end

      def append_info_to_payload(payload)
        super
        payload[:groonga_runtime] = GroongaClientModel::LogSubscriber.runtime
      end

      module ClassMethods
        def log_process_action(payload)
          messages = super
          groonga_runtime = payload[:groonga_runtime]
          if groonga_runtime
            messages << ("Groonga: %.1fms" % groonga_runtime.to_f)
          end
          messages
        end
      end
    end
  end
end
