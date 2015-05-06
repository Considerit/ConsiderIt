class CreateNotifications < ActiveRecord::Migration
  def change
    create_table :notifications do |t|
      t.integer   "user_id"
      t.integer   "notifier_id"
      t.integer   "subdomain_id"
      t.string "notifier_type"
      t.string "event_type"
      t.string "event_channel"      
      t.boolean   "sent_email"
      t.datetime  "read_at"   

      t.datetime  "created_at"
      t.datetime  "updated_at"
    end
  end
end
