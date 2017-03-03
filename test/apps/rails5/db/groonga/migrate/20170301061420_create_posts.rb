class CreatePosts < GroongaClientModel::Migration
  def change
    create_table :posts do |t|
      t.short_text :title
      t.text :body
    end
  end
end
