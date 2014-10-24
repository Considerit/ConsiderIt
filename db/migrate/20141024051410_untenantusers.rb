class Untenantusers < ActiveRecord::Migration
  def change
    add_column :accounts, :roles, :text
    add_column :users, :active_in, :text
    add_column :users, :super_admin, :boolean, :default => false
  end
end
