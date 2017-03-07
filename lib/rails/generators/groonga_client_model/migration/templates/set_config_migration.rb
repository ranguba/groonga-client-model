class <%= migration_class_name %> < GroongaClientModel::Migration
  def up
    set_config "<%= @config_key %>", "<%= @config_value %>"
  end

  def down
    # set_config "<%= @config_key %>", "old value"
    # delete_config "<%= @config_key %>"
  end
end
