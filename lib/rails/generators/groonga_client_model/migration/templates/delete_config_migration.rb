class <%= migration_class_name %> < GroongaClientModel::Migration
  def up
    delete_config "<%= @config_key %>"
  end

  def down
    # set_config "<%= @config_key %>", "old value"
  end
end
