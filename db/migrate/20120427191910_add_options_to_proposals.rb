class AddOptionsToProposals < ActiveRecord::Migration
  def change
    add_column :proposals, :session_id, :string
    add_column :proposals, :require_login, :boolean, :default => false
    add_column :proposals, :email_creator_per_position, :boolean, :default => false

    add_column :proposals, :long_id, :string, :unique => true
    add_column :proposals, :admin_id, :string, :unique => true

    add_column :proposals, :user_id, :integer
    add_index :proposals, :long_id, :unique => true
    add_index :proposals, :admin_id, :unique => true

  end
end
