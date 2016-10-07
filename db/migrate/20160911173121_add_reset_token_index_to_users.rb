class AddResetTokenIndexToUsers < ActiveRecord::Migration
  def change
    add_index :users, :reset_password_token, :length => 3
  end
end
