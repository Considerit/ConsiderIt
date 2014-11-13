class AddEmailSuppressionToUsers < ActiveRecord::Migration
  def change
    add_column :users, :no_email_notifications, :boolean, :default => false
  end
end
