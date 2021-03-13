ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors)

  # Add more helper methods to be used by all tests here...
end

require "groonga_client_model/test_helper"
class ActiveSupport::TestCase
  include GroongaClientModel::TestHelper
  include FactoryBot::Syntax::Methods
end
