require "test_helper"
require "rails/generators/groonga_client_model/migration_generator"

class MigrationGeneratorTest < Rails::Generators::TestCase
  tests GroongaClientModel::Generators::MigrationGenerator
  destination File.expand_path("../tmp", __dir__)
  setup :prepare_destination

  test "add_column" do
    run_generator(["add_title_to_posts", "title:short_text"])
    assert_migration("db/groonga/migrate/add_title_to_posts.rb", <<-MIGRATION)
class AddTitleToPosts < GroongaClientModel::Migration
  def change
    add_column :posts, :title, :short_text
  end
end
    MIGRATION
  end

  test "remove_column" do
    run_generator(["remove_title_from_posts", "title"])
    assert_migration("db/groonga/migrate/remove_title_from_posts.rb", <<-MIGRATION)
class RemoveTitleFromPosts < GroongaClientModel::Migration
  def change
    remove_column :posts, :title
  end
end
    MIGRATION
  end

  test "create_table" do
    run_generator(["create_posts"])
    assert_migration("db/groonga/migrate/create_posts.rb", <<-MIGRATION)
class CreatePosts < GroongaClientModel::Migration
  def change
    create_table :posts do |t|
    end
  end
end
    MIGRATION
  end

  test "set_config" do
    run_generator(["set_config_alias_column"])
    assert_migration("db/groonga/migrate/set_config_alias_column.rb", <<-MIGRATION)
class SetConfigAliasColumn < GroongaClientModel::Migration
  def up
    config_set "alias.column", "new value"
  end

  def down
    # config_set "alias.column", "old value"
    # config_delete "alias.column"
  end
end
    MIGRATION
  end

  test "delete_config" do
    run_generator(["delete_config_alias_column"])
    assert_migration("db/groonga/migrate/delete_config_alias_column.rb", <<-MIGRATION)
class DeleteConfigAliasColumn < GroongaClientModel::Migration
  def up
    config_delete "alias.column"
  end

  def down
    # config_set "alias.column", "old value"
  end
end
    MIGRATION
  end
end
