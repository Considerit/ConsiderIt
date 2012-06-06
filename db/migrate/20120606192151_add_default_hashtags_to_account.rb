class AddDefaultHashtagsToAccount < ActiveRecord::Migration
  def change
    add_column :accounts, :default_hashtags, :string
  end
end
