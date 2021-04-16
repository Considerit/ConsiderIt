class RemoveUnusedFields < ActiveRecord::Migration[5.2]
  def change
    remove_column :subdomains, :moderate_points_mode
    remove_column :subdomains, :moderate_comments_mode
    remove_column :subdomains, :moderate_proposals_mode
    remove_column :subdomains, :assessment_enabled
    remove_column :subdomains, :host
    remove_column :subdomains, :host_with_port
    remove_column :subdomains, :has_civility_pledge
    remove_column :subdomains, :notifications_sender_email
    remove_column :subdomains, :app_title
    remove_column :subdomains, :branding

    remove_column :users, :reset_password_sent_at
    remove_column :users, :no_email_notifications
    remove_column :users, :groups

    remove_column :proposals, :trending
    remove_column :proposals, :activity
    remove_column :proposals, :provocative
    remove_column :proposals, :contested
    remove_column :proposals, :num_points
    remove_column :proposals, :num_pros
    remove_column :proposals, :num_cons
    remove_column :proposals, :num_comments
    remove_column :proposals, :num_inclusions
    remove_column :proposals, :num_perspectives
    remove_column :proposals, :num_supporters
    remove_column :proposals, :num_opposers
    remove_column :proposals, :followable_last_notification_milestone
    remove_column :proposals, :followable_last_notification
    remove_column :proposals, :publicity
    remove_column :proposals, :access_list
    remove_column :proposals, :description_fields
    remove_column :proposals, :zips

    remove_column :points, :num_inclusions

  end
end
