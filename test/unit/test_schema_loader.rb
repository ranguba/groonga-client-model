class TestSchemaLoader < Test::Unit::TestCase
  test("raise error when load directory") do
    assert_raise(Errno::EISDIR) do
      GroongaClientModel::SchemaLoader.new(Pathname.new(".")).load
    end
  end
end
