class CreateNotifications < ActiveRecord::Migration
  def change
    add_column :users, :subscriptions, :text
    add_column :users, :emails, :text

    create_table :notifications do |t|
      t.integer   "subdomain_id"
      t.integer   "user_id"

      t.string    "digest_object_type"
      t.integer   "digest_object_id"
      t.string    "event_object_type"
      t.integer   "event_object_id"

      t.string    "digest_object_relationship"   
      t.string    "event_object_relationship"   

      t.string    "event_type"

      t.boolean   "sent_email"
      t.datetime  "read_at"   

      t.datetime  "created_at"
    end
  end
end
