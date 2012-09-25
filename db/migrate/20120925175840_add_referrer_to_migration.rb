class AddReferrerToMigration < ActiveRecord::Migration
  def change
    add_column :users, :referer, :text
  end
end
