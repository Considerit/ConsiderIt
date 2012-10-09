class AddResetPasswordAtToUsers < ActiveRecord::Migration
  def change
    begin
      add_column :users, :reset_password_sent_at, :datetime
    rescue
    end
  end
end
