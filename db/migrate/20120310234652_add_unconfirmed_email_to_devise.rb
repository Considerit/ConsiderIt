#TODO: this file should be removed
class AddUnconfirmedEmailToDevise < ActiveRecord::Migration
  def change
    begin
      add_column :users, :unconfirmed_email, :string
      add_column :users, :reset_password_sent_at, :datetime
    rescue
    end
  end
end
