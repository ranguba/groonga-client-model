require 'test_helper'

class AgeTest < ActiveSupport::TestCase
  include GroongaClientModel::TestHelper

  test "validate: _key: invalid: string" do
    key = "Hello"
    age = Age.new(_key: key)
    assert(age.invalid?)
    assert_equal({
                   _key: [
                     age.errors.generate_message(:_key,
                                                 :not_a_positive_integer,
                                                 inspected_value: key.inspect)
                   ],
                 },
                 age.errors.messages)
  end
end
