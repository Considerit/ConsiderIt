class AddLangToUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :lang, :string
  end
end
