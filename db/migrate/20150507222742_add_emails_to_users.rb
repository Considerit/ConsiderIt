class AddEmailsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :emails, :text
  end
end
