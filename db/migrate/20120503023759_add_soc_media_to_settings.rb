class AddSocMediaToSettings < ActiveRecord::Migration
  def change
    add_column :accounts, :socmedia_facebook_id, :string
    add_column :accounts, :socmedia_facebook_secret, :string
    add_column :accounts, :socmedia_twitter_consumer_key, :string
    add_column :accounts, :socmedia_twitter_consumer_secret, :string
    add_column :accounts, :socmedia_twitter_oauth_token, :string
    add_column :accounts, :socmedia_twitter_oauth_token_secret, :string

    rename_column :accounts, :socmedia_twitter_page, :socmedia_twitter_account
    rename_column :accounts, :app_notification_email, :contact_email
  end
end
