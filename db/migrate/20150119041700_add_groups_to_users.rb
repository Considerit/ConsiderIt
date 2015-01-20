class AddGroupsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :groups, :text
  end
end
