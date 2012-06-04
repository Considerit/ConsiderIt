class AddFollowableForComment < ActiveRecord::Migration
  def change
    add_column :comments, :followable_last_notification_milestone, :integer, :default => 0
    add_column :comments, :followable_last_notification, :datetime
  end
end
