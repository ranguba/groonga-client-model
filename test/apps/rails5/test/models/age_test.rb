require 'test_helper'

class AgeTest < ActiveSupport::TestCase
  include GroongaClientModel::TestHelper

  test "validate: _key: invalid: string" do
    key = "Hello"
    age = Age.new(_key: key)
    assert(age.invalid?)
    assert_equal([age.errors.generate_message(:_key,
                                              :not_a_positive_integer,
                                              inspected_value: key.inspect)])
                 age.errors.full_messages)
  end
end
