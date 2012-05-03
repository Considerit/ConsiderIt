class UpdateMessagePreferences < ActiveRecord::Migration
  def change
    rename_column :positions, :notification_statement_subscriber, :notification_perspective_subscriber
    rename_column :positions, :notification_proposal_subscriber, :notification_point_subscriber
    rename_column :positions, :notification_includer, :notification_demonstrated_interest

    add_column :positions, :notification_author, :boolean, :default => true
    change_column :positions, :notification_demonstrated_interest, :boolean, :default => true

    remove_column :users, :notification_commenter
    remove_column :users, :notification_author
    remove_column :users, :notification_responder
    remove_column :users, :notification_reflector

  end
end
