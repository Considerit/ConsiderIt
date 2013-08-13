class AddUpdatedSinceAndPreviouslyPassedToModeration < ActiveRecord::Migration
  def change
    add_column :moderations, :updated_since_last_evaluation, :boolean, :default => false
    add_column :moderations, :notification_sent, :boolean, :default => false
  end
end
