class ContinueRenamingColumns2 < ActiveRecord::Migration
  def change
    rename_column :subdomains, :contact_email, :notifications_sender_email
    rename_column :subdomains, :project_url, :external_external_project_url
    rename_column :subdomains, :analytics_google, :google_analytics_code
    rename_column :subdomains, :requires_civility_pledge_on_registration, :has_civility_pledge
    remove_column :subdomains, :enable_user_conversations

    rename_column :users, :registration_complete, :registered

    remove_column :points, :long_id

    rename_column :proposals, :long_id, :slug
  end
end
