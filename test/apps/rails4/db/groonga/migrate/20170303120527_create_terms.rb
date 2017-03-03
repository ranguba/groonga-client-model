class CreateTerms < GroongaClientModel::Migration
  def change
    create_table :terms, propose: :full_text_search do |t|
      t.index :posts, :body
    end
  end
end
