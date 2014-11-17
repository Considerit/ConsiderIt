class DropUnusedColumns < ActiveRecord::Migration
  def change
    remove_column :accounts, :theme
    remove_column :accounts, :socmedia_facebook_page
    remove_column :accounts, :socmedia_twitter_account
    remove_column :accounts, :app_require_registration_for_perspective
    remove_column :accounts, :socmedia_facebook_client
    remove_column :accounts, :socmedia_facebook_secret
    remove_column :accounts, :socmedia_twitter_consumer_key
    remove_column :accounts, :socmedia_twitter_consumer_secret
    remove_column :accounts, :socmedia_twitter_oauth_token
    remove_column :accounts, :socmedia_twitter_oauth_token_secret
    remove_column :accounts, :default_hashtags
    remove_column :accounts, :tweet_notifications
    remove_column :accounts, :inherited_themes
    remove_column :accounts, :pro_label
    remove_column :accounts, :con_label
    remove_column :accounts, :slider_right
    remove_column :accounts, :slider_left
    remove_column :accounts, :slider_prompt
    remove_column :accounts, :considerations_prompt
    remove_column :accounts, :statement_prompt
    remove_column :accounts, :entity
    remove_column :accounts, :enable_position_statement
    remove_column :accounts, :enable_moderation
    remove_column :accounts, :single_page
    remove_column :accounts, :managing_account_id
    remove_column :accounts, :header_text
    remove_column :accounts, :header_details_text
    remove_column :accounts, :enable_hibernation
    remove_column :accounts, :hibernation_message
    remove_column :accounts, :enable_sharing
    remove_column :accounts, :followable_last_notification_milestone
    remove_column :accounts, :followable_last_notification

    remove_column :proposals, :slider_right
    remove_column :proposals, :slider_left
    remove_column :proposals, :slider_prompt
    remove_column :proposals, :considerations_prompt
    remove_column :proposals, :statement_prompt
    remove_column :proposals, :entity
    remove_column :proposals, :short_name
    remove_column :proposals, :image
    remove_column :proposals, :url1
    remove_column :proposals, :url2
    remove_column :proposals, :url3
    remove_column :proposals, :url4
    remove_column :proposals, :domain
    remove_column :proposals, :domain_short
    remove_column :proposals, :additional_description1
    remove_column :proposals, :additional_description2
    remove_column :proposals, :additional_description3
    remove_column :proposals, :headers
    remove_column :proposals, :discussion_mode
    remove_column :proposals, :enable_position_statement
    remove_column :proposals, :session_id
    remove_column :proposals, :require_login
    remove_column :proposals, :email_creator_per_position
    remove_column :proposals, :admin_id
    remove_column :proposals, :num_views
    remove_column :proposals, :num_unpublished_opinions
    remove_column :proposals, :start_date
    remove_column :proposals, :end_date
    remove_column :proposals, :top_pro
    remove_column :proposals, :top_con
    remove_column :proposals, :participants
    remove_column :proposals, :tags
    remove_column :proposals, :slider_middle

    remove_column :assessments, :qualifies
    remove_column :assessments, :qualifies_reason

    remove_column :claims, :notes

    remove_column :comments, :title
    remove_column :comments, :subject
    remove_column :comments, :followable_last_notification_milestone
    remove_column :comments, :followable_last_notification
    remove_column :comments, :thanks_count

    remove_column :inclusions, :opinion_id
    remove_column :inclusions, :session_id
    remove_column :inclusions, :included_as_pro

    remove_column :opinions, :session_id
    remove_column :opinions, :followable_last_notification_milestone
    remove_column :opinions, :followable_last_notification
    remove_column :opinions, :long_id

    remove_column :points, :opinion_id
    remove_column :points, :session_id
    remove_column :points, :unique_listings
    remove_column :points, :persuasiveness
    remove_column :points, :attention
    remove_column :points, :score_stance_group_0
    remove_column :points, :score_stance_group_1
    remove_column :points, :score_stance_group_2
    remove_column :points, :score_stance_group_3
    remove_column :points, :score_stance_group_4
    remove_column :points, :score_stance_group_5
    remove_column :points, :score_stance_group_6
    remove_column :points, :share
    remove_column :points, :followable_last_notification_milestone
    remove_column :points, :followable_last_notification
    remove_column :points, :point_link_count
    remove_column :points, :divisiveness

    remove_column :users, :unconfirmed_email
    remove_column :users, :remember_created_at
    remove_column :users, :sign_in_count
    remove_column :users, :current_sign_in_at
    remove_column :users, :last_sign_in_at
    remove_column :users, :current_sign_in_ip
    remove_column :users, :last_sign_in_ip
    remove_column :users, :confirmation_token
    remove_column :users, :confirmed_at
    remove_column :users, :confirmation_sent_at
    remove_column :users, :sessions
    remove_column :users, :yahoo_uid
    remove_column :users, :domain_id
    remove_column :users, :roles_mask
    remove_column :users, :referer
    remove_column :users, :metric_influence
    remove_column :users, :metric_points
    remove_column :users, :metric_comments
    remove_column :users, :metric_conversations
    remove_column :users, :metric_opinions

  end
end
