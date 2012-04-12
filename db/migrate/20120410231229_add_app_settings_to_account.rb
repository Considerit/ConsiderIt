class AddAppSettingsToAccount < ActiveRecord::Migration
  def change
    add_column :accounts, :appearance_base_color, :string
    add_column :accounts, :appearance_style, :string

    add_column :accounts, :app_title, :string
    add_column :accounts, :app_notification_email, :string
    add_column :accounts, :app_creation_permission, :integer

    add_column :accounts, :socmedia_facebook_page, :string
    add_column :accounts, :socmedia_twitter_page, :string

    add_column :accounts, :analytics_google, :string
      
  end
end
