class AddTweetToAccount < ActiveRecord::Migration
  def change
    add_column :accounts, :tweet_notifications, :boolean, :default => false
  end
end
