class <%= migration_class_name %> < GroongaClientModel::Migration
  def up
    config_delete "<%= @config_key %>"
  end

  def down
    # config_set "<%= @config_key %>", "old value"
  end
end
