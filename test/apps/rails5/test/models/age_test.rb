require 'test_helper'

class AgeTest < ActiveSupport::TestCase
  include GroongaClientModel::TestHelper

  test "validate: _key: invalid: string" do
    age = Age.new(_key: "Hello")
    assert(age.invalid?)
    assert_equal(["Key must be positive integer: \"Hello\""],
                 age.errors.full_messages)
  end
end
