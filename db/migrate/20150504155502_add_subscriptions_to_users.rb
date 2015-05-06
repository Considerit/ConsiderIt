class AddSubscriptionsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :subscriptions, :text
  end
end
