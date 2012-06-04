class AddSecureTokenToUser < ActiveRecord::Migration
  def change
    add_column :users, :unique_token, :string, :unique => true
  end
end
