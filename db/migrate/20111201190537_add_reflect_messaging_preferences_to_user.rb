class AddReflectMessagingPreferencesToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :notification_reflector, :boolean, :default => true
    add_column :users, :notification_responder, :boolean, :default => true
  end

  def self.down
    remove_column :users, :notification_reflector
    remove_column :users, :notification_responder
  end
end
