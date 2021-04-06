class AddIndexesToNotifications < ActiveRecord::Migration[5.2]
  def change
    add_index :notifications, :subdomain_id
    add_index :notifications, :user_id
    add_index :notifications, :digest_object_type
    add_index :notifications, :digest_object_id

  end
end
