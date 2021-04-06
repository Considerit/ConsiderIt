class AddResetTokenIndexToUsers < ActiveRecord::Migration[5.2]
  def change
    add_index :users, :reset_password_token, :length => 3
  end
end
