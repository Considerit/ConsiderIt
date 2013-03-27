class AddMoreIndexes < ActiveRecord::Migration
  def change

    remove_index :accounts, :name => 'index_accounts_on_identifier'

    add_index :points, [:account_id, :proposal_id, :id, :is_pro], :name => 'select_included_points'    
    add_index :points, [:account_id, :proposal_id, :published, :id, :is_pro], :name => 'select_published_included_points'    
    add_index :users, [:account_id, :avatar_file_name], :name => 'select_user_by_avatar_name', :length => {:avatar_file_name => 3}
    add_index :users, [:account_id], :name => 'select_user_by_account'
    add_index :users, [:account_id, :id], :name => 'select_user_by_account_and_id'
    add_index :accounts, :identifier, :length => 10, :name => 'by_identifier'
    add_index :proposals, [:account_id, :active], :name => 'select_proposal_by_active'


  end
end
