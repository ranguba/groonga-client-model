class CreateAges < GroongaClientModel::Migration
  def change
    create_table :ages, type: :hash_table, key_type: :uint32 do |t|
    end
  end
end
