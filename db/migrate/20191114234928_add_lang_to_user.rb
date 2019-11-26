class AddLangToUser < ActiveRecord::Migration
  def change
    add_column :users, :lang, :string
  end
end
