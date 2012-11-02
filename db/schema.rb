# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20121102000241) do

  create_table "accounts", :force => true do |t|
    t.string   "identifier"
    t.string   "theme"
    t.datetime "created_at",                                                  :null => false
    t.datetime "updated_at",                                                  :null => false
    t.string   "app_title"
    t.string   "contact_email"
    t.integer  "app_proposal_creation_permission"
    t.string   "socmedia_facebook_page"
    t.string   "socmedia_twitter_account"
    t.string   "analytics_google"
    t.boolean  "app_require_registration_for_perspective", :default => false
    t.string   "socmedia_facebook_client"
    t.string   "socmedia_facebook_secret"
    t.string   "socmedia_twitter_consumer_key"
    t.string   "socmedia_twitter_consumer_secret"
    t.string   "socmedia_twitter_oauth_token"
    t.string   "socmedia_twitter_oauth_token_secret"
    t.boolean  "requires_civility_pledge_on_registration", :default => false
    t.integer  "followable_last_notification_milestone"
    t.datetime "followable_last_notification"
    t.string   "default_hashtags"
    t.boolean  "tweet_notifications",                      :default => false
    t.string   "host"
    t.string   "host_with_port"
    t.string   "inherited_themes"
    t.string   "pro_label"
    t.string   "con_label"
    t.string   "slider_right"
    t.string   "slider_left"
    t.string   "slider_prompt"
    t.string   "considerations_prompt"
    t.string   "statement_prompt"
    t.string   "entity"
    t.boolean  "enable_position_statement"
  end

  add_index "accounts", ["identifier"], :name => "index_accounts_on_identifier"

  create_table "active_admin_comments", :force => true do |t|
    t.string   "resource_id",   :null => false
    t.string   "resource_type", :null => false
    t.integer  "author_id"
    t.string   "author_type"
    t.text     "body"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
    t.string   "namespace"
  end

  add_index "active_admin_comments", ["author_type", "author_id"], :name => "index_active_admin_comments_on_author_type_and_author_id"
  add_index "active_admin_comments", ["namespace"], :name => "index_active_admin_comments_on_namespace"
  add_index "active_admin_comments", ["resource_type", "resource_id"], :name => "index_admin_notes_on_resource_type_and_resource_id"

  create_table "activities", :force => true do |t|
    t.string   "action_type", :null => false
    t.integer  "action_id",   :null => false
    t.integer  "account_id",  :null => false
    t.integer  "user_id"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  add_index "activities", ["account_id"], :name => "index_activities_on_account_id"

  create_table "assessments", :force => true do |t|
    t.integer  "user_id"
    t.integer  "account_id"
    t.integer  "assessable_id"
    t.string   "assessable_type"
    t.boolean  "qualifies"
    t.string   "qualifies_reason"
    t.integer  "overall_verdict"
    t.boolean  "complete",         :default => false
    t.datetime "created_at",                          :null => false
    t.datetime "updated_at",                          :null => false
    t.boolean  "reviewable",       :default => false
  end

  create_table "claims", :force => true do |t|
    t.integer  "assessment_id"
    t.integer  "account_id"
    t.text     "result"
    t.text     "claim"
    t.integer  "verdict"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
    t.text     "notes"
  end

  create_table "comments", :force => true do |t|
    t.integer  "commentable_id",                         :default => 0
    t.string   "commentable_type",                       :default => ""
    t.string   "title",                                  :default => ""
    t.text     "body"
    t.string   "subject",                                :default => ""
    t.integer  "user_id",                                :default => 0,  :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "passes_moderation"
    t.integer  "account_id"
    t.integer  "followable_last_notification_milestone", :default => 0
    t.datetime "followable_last_notification"
    t.integer  "moderation_status"
  end

  add_index "comments", ["account_id", "commentable_id", "commentable_type", "moderation_status"], :name => "select_comments"
  add_index "comments", ["account_id", "commentable_id", "commentable_type"], :name => "select_comments_on_commentable"
  add_index "comments", ["account_id"], :name => "index_comments_on_account_id"
  add_index "comments", ["commentable_id"], :name => "index_comments_on_commentable_id"
  add_index "comments", ["user_id"], :name => "index_comments_on_user_id"

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
  end

  add_index "delayed_jobs", ["priority", "run_at"], :name => "delayed_jobs_priority"

  create_table "domain_maps", :force => true do |t|
    t.integer "proposal_id"
    t.integer "domain_id"
    t.integer "account_id"
  end

  add_index "domain_maps", ["account_id"], :name => "index_domain_maps_on_account_id"

  create_table "domains", :force => true do |t|
    t.integer "identifier"
    t.string  "name"
    t.integer "account_id"
  end

  add_index "domains", ["account_id"], :name => "index_domains_on_account_id"
  add_index "domains", ["identifier"], :name => "index_domains_on_identifier"

  create_table "emails", :force => true do |t|
    t.string   "from_address",                           :null => false
    t.string   "reply_to_address"
    t.string   "subject"
    t.text     "to_address"
    t.text     "cc_address"
    t.text     "bcc_address"
    t.text     "content",          :limit => 2147483647
    t.datetime "sent_at"
    t.datetime "created_at",                             :null => false
    t.datetime "updated_at",                             :null => false
  end

  create_table "follows", :force => true do |t|
    t.integer  "user_id"
    t.integer  "followable_id"
    t.string   "followable_type"
    t.boolean  "follow",          :default => true
    t.boolean  "explicit",        :default => false
    t.integer  "account_id"
    t.datetime "created_at",                         :null => false
    t.datetime "updated_at",                         :null => false
  end

  create_table "inclusions", :force => true do |t|
    t.integer  "proposal_id"
    t.integer  "position_id"
    t.integer  "point_id"
    t.integer  "user_id"
    t.integer  "session_id"
    t.boolean  "included_as_pro"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.integer  "version"
    t.integer  "account_id"
  end

  add_index "inclusions", ["account_id"], :name => "index_inclusions_on_account_id"
  add_index "inclusions", ["point_id"], :name => "index_inclusions_on_point_id"
  add_index "inclusions", ["user_id"], :name => "index_inclusions_on_user_id"

  create_table "moderations", :force => true do |t|
    t.integer  "user_id"
    t.integer  "moderatable_id"
    t.string   "moderatable_type"
    t.integer  "status"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
    t.integer  "account_id"
  end

  create_table "point_listings", :force => true do |t|
    t.integer  "proposal_id"
    t.integer  "position_id"
    t.integer  "point_id"
    t.integer  "user_id"
    t.integer  "inclusion_id"
    t.integer  "session_id"
    t.integer  "context"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "account_id"
  end

  add_index "point_listings", ["account_id"], :name => "index_point_listings_on_account_id"
  add_index "point_listings", ["point_id"], :name => "index_point_listings_on_point_id"
  add_index "point_listings", ["position_id"], :name => "index_point_listings_on_position_id"

  create_table "point_similarities", :force => true do |t|
    t.integer  "p1_id"
    t.integer  "p2_id"
    t.integer  "proposal_id"
    t.integer  "user_id"
    t.integer  "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "points", :force => true do |t|
    t.integer  "proposal_id"
    t.integer  "position_id"
    t.integer  "user_id"
    t.integer  "session_id"
    t.text     "nutshell"
    t.text     "text"
    t.boolean  "is_pro"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "num_inclusions"
    t.integer  "unique_listings"
    t.float    "score"
    t.float    "attention"
    t.float    "persuasiveness"
    t.float    "appeal"
    t.float    "score_stance_group_0"
    t.float    "score_stance_group_1"
    t.float    "score_stance_group_2"
    t.float    "score_stance_group_3"
    t.float    "score_stance_group_4"
    t.float    "score_stance_group_5"
    t.float    "score_stance_group_6"
    t.datetime "deleted_at"
    t.integer  "version"
    t.boolean  "published",                              :default => true
    t.boolean  "hide_name",                              :default => false
    t.boolean  "share",                                  :default => true
    t.boolean  "passes_moderation"
    t.integer  "account_id"
    t.integer  "followable_last_notification_milestone"
    t.datetime "followable_last_notification"
    t.integer  "comment_count",                          :default => 0
    t.integer  "point_link_count",                       :default => 0
    t.text     "includers"
    t.float    "divisiveness"
    t.integer  "moderation_status"
  end

  add_index "points", ["account_id", "proposal_id", "published", "is_pro"], :name => "select_published_pros_or_cons"
  add_index "points", ["account_id", "proposal_id", "published", "moderation_status", "is_pro"], :name => "select_acceptable_pros_or_cons"
  add_index "points", ["account_id"], :name => "index_points_on_account_id"
  add_index "points", ["is_pro"], :name => "index_points_on_is_pro"
  add_index "points", ["proposal_id"], :name => "index_points_on_option_id"

  create_table "positions", :force => true do |t|
    t.integer  "proposal_id"
    t.integer  "user_id"
    t.integer  "session_id"
    t.text     "explanation"
    t.float    "stance"
    t.integer  "stance_bucket"
    t.boolean  "published",                              :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.integer  "version"
    t.boolean  "notification_demonstrated_interest",     :default => true
    t.boolean  "notification_point_subscriber"
    t.boolean  "notification_perspective_subscriber"
    t.integer  "account_id"
    t.boolean  "notification_author",                    :default => true
    t.integer  "followable_last_notification_milestone"
    t.datetime "followable_last_notification"
  end

  add_index "positions", ["account_id", "proposal_id", "published"], :name => "index_positions_on_account_id_and_proposal_id_and_published"
  add_index "positions", ["account_id"], :name => "index_positions_on_account_id"
  add_index "positions", ["proposal_id"], :name => "index_positions_on_option_id"
  add_index "positions", ["published"], :name => "index_positions_on_published"
  add_index "positions", ["stance_bucket"], :name => "index_positions_on_stance_bucket"
  add_index "positions", ["user_id"], :name => "index_positions_on_user_id"

  create_table "proposals", :force => true do |t|
    t.string   "designator"
    t.string   "category"
    t.string   "name"
    t.string   "short_name"
    t.text     "description"
    t.string   "image"
    t.string   "url"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "domain"
    t.string   "domain_short"
    t.text     "long_description",                       :limit => 2147483647
    t.text     "additional_details",                     :limit => 2147483647
    t.string   "slider_prompt"
    t.string   "considerations_prompt"
    t.string   "statement_prompt"
    t.string   "headers"
    t.string   "entity"
    t.string   "discussion_mode"
    t.boolean  "enable_position_statement"
    t.integer  "account_id"
    t.string   "session_id"
    t.boolean  "require_login",                                                :default => false
    t.boolean  "email_creator_per_position",                                   :default => false
    t.string   "long_id"
    t.string   "admin_id"
    t.integer  "user_id"
    t.string   "slider_right"
    t.string   "slider_left"
    t.float    "trending"
    t.float    "activity"
    t.float    "provocative"
    t.float    "contested"
    t.integer  "num_points"
    t.integer  "num_pros"
    t.integer  "num_cons"
    t.integer  "num_comments"
    t.integer  "num_inclusions"
    t.integer  "num_perspectives"
    t.integer  "num_supporters"
    t.integer  "num_opposers"
    t.integer  "num_views"
    t.integer  "num_unpublished_positions"
    t.integer  "followable_last_notification_milestone"
    t.datetime "followable_last_notification"
    t.datetime "start_date"
    t.datetime "end_date"
    t.boolean  "active",                                                       :default => true
    t.integer  "moderation_status"
  end

  add_index "proposals", ["account_id", "id"], :name => "select_proposal"
  add_index "proposals", ["account_id", "long_id"], :name => "select_proposal_by_long_id"
  add_index "proposals", ["account_id"], :name => "index_proposals_on_account_id"
  add_index "proposals", ["long_id"], :name => "index_proposals_on_long_id", :unique => true

  create_table "rails_admin_histories", :force => true do |t|
    t.string   "message"
    t.string   "username"
    t.integer  "item"
    t.string   "table"
    t.integer  "month",      :limit => 2
    t.integer  "year",       :limit => 8
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "rails_admin_histories", ["item", "table", "month", "year"], :name => "index_histories_on_item_and_table_and_month_and_year"

  create_table "reflect_bullet_revisions", :force => true do |t|
    t.integer  "bullet_id"
    t.integer  "comment_id"
    t.text     "text"
    t.integer  "user_id"
    t.boolean  "active",       :default => true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "account_id"
    t.text     "comment_type"
  end

  add_index "reflect_bullet_revisions", ["account_id"], :name => "index_reflect_bullet_revisions_on_account_id"

  create_table "reflect_bullets", :force => true do |t|
    t.integer  "comment_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "account_id"
    t.text     "comment_type"
  end

  add_index "reflect_bullets", ["account_id"], :name => "index_reflect_bullets_on_account_id"

  create_table "reflect_highlights", :force => true do |t|
    t.integer  "bullet_id"
    t.integer  "bullet_rev"
    t.string   "element_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "account_id"
  end

  add_index "reflect_highlights", ["account_id"], :name => "index_reflect_highlights_on_account_id"

  create_table "reflect_response_revisions", :force => true do |t|
    t.integer  "bullet_id"
    t.integer  "bullet_rev"
    t.integer  "response_id"
    t.text     "text"
    t.integer  "user_id"
    t.integer  "signal"
    t.boolean  "active",      :default => true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "account_id"
  end

  add_index "reflect_response_revisions", ["account_id"], :name => "index_reflect_response_revisions_on_account_id"

  create_table "reflect_responses", :force => true do |t|
    t.integer  "bullet_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "account_id"
  end

  add_index "reflect_responses", ["account_id"], :name => "index_reflect_responses_on_account_id"

  create_table "requests", :force => true do |t|
    t.integer  "user_id"
    t.integer  "assessment_id"
    t.integer  "account_id"
    t.text     "suggestion"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "taggings", :force => true do |t|
    t.integer  "tag_id"
    t.integer  "account_id"
    t.integer  "taggable_id"
    t.string   "taggable_type"
    t.integer  "tagger_id"
    t.string   "tagger_type"
    t.string   "context",       :limit => 128
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id"], :name => "index_taggings_on_tag_id"
  add_index "taggings", ["taggable_id", "taggable_type", "context"], :name => "index_taggings_on_taggable_id_and_taggable_type_and_context"

  create_table "tags", :force => true do |t|
    t.string  "name"
    t.integer "account_id"
  end

  create_table "users", :force => true do |t|
    t.integer  "account_id"
    t.string   "unique_token"
    t.string   "email",                                 :default => ""
    t.string   "unconfirmed_email"
    t.string   "encrypted_password",     :limit => 128, :default => ""
    t.string   "reset_password_token"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                         :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "sessions"
    t.boolean  "admin",                                 :default => false
    t.string   "avatar_file_name"
    t.string   "avatar_content_type"
    t.integer  "avatar_file_size"
    t.datetime "avatar_updated_at"
    t.string   "avatar_remote_url"
    t.string   "name"
    t.text     "bio"
    t.string   "url"
    t.string   "facebook_uid"
    t.string   "google_uid"
    t.string   "yahoo_uid"
    t.string   "openid_uid"
    t.string   "twitter_uid"
    t.string   "twitter_handle"
    t.boolean  "registration_complete",                 :default => false
    t.integer  "domain_id"
    t.integer  "roles_mask",                            :default => 0
    t.text     "referer"
    t.datetime "reset_password_sent_at"
  end

  add_index "users", ["account_id"], :name => "account_id"
  add_index "users", ["email"], :name => "index_users_on_email"
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

  create_table "versions", :force => true do |t|
    t.string   "item_type",  :null => false
    t.integer  "item_id",    :null => false
    t.string   "event",      :null => false
    t.string   "whodunnit"
    t.text     "object"
    t.datetime "created_at"
  end

  add_index "versions", ["item_type", "item_id"], :name => "index_versions_on_item_type_and_item_id"

end
