class AddIndexesToNotifications2 < ActiveRecord::Migration
  def change
    add_index :notifications, :event_object_type
    add_index :notifications, :event_object_id

  end
end
