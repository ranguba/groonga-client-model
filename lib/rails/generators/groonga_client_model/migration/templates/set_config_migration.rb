class <%= migration_class_name %> < GroongaClientModel::Migration
  def up
    config_set "<%= @config_key %>", "<%= @config_value %>"
  end

  def down
    # config_set "<%= @config_key %>", "old value"
    # config_delete "<%= @config_key %>"
  end
end
