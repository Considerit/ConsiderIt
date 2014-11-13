class RemoveTenantIndexesOnUser < ActiveRecord::Migration
  def change
    remove_index :users, :name => 'select_user_by_avatar_name'
    remove_index :users, :name => 'select_user_by_account_and_id'
    remove_index :users, :name => 'account_id'
    remove_index :users, :name => 'select_user_by_account'

    add_index :users, :avatar_file_name
  end
end
