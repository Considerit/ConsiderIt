class AddMessagingPreferencesToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :notification_commenter, :boolean, :default => true
    add_column :users, :notification_author, :boolean, :default => true
    add_column :positions, :notification_includer, :boolean
    add_column :positions, :notification_option_subscriber, :boolean
  end

  def self.down
    remove_column :users, :notification_commenter
    remove_column :users, :notification_author
    remove_column :positions, :notification_includer
    remove_column :positions, :notification_option_subscriber
  end
end
