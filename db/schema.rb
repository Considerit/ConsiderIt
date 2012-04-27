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

ActiveRecord::Schema.define(:version => 20120427191910) do

  create_table "accounts", :force => true do |t|
    t.string   "identifier"
    t.string   "theme"
    t.datetime "created_at",              :null => false
    t.datetime "updated_at",              :null => false
    t.string   "appearance_base_color"
    t.string   "appearance_style"
    t.string   "app_title"
    t.string   "app_notification_email"
    t.integer  "app_creation_permission"
    t.string   "socmedia_facebook_page"
    t.string   "socmedia_twitter_page"
    t.string   "analytics_google"
  end

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

  create_table "admin_users", :force => true do |t|
    t.string   "email",                  :default => "", :null => false
    t.string   "encrypted_password",     :default => "", :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                             :null => false
    t.datetime "updated_at",                             :null => false
  end

  add_index "admin_users", ["email"], :name => "index_admin_users_on_email", :unique => true
  add_index "admin_users", ["reset_password_token"], :name => "index_admin_users_on_reset_password_token", :unique => true

  create_table "comments", :force => true do |t|
    t.integer  "commentable_id",    :default => 0
    t.string   "commentable_type",  :default => ""
    t.string   "title",             :default => ""
    t.text     "body"
    t.string   "subject",           :default => ""
    t.integer  "user_id",           :default => 0,  :null => false
    t.integer  "parent_id"
    t.integer  "lft"
    t.integer  "rgt"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "point_id"
    t.integer  "option_id"
    t.boolean  "passes_moderation"
  end

  add_index "comments", ["commentable_id"], :name => "index_comments_on_commentable_id"
  add_index "comments", ["user_id"], :name => "index_comments_on_user_id"

  create_table "domain_maps", :force => true do |t|
    t.integer "proposal_id"
    t.integer "domain_id"
  end

  create_table "domains", :force => true do |t|
    t.integer "identifier"
    t.string  "name"
  end

  add_index "domains", ["identifier"], :name => "index_domains_on_identifier"

  create_table "inclusion_versions", :force => true do |t|
    t.integer  "inclusion_id"
    t.integer  "version"
    t.integer  "option_id"
    t.integer  "position_id"
    t.integer  "point_id"
    t.integer  "user_id"
    t.integer  "session_id"
    t.boolean  "included_as_pro"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  add_index "inclusion_versions", ["inclusion_id"], :name => "index_inclusion_versions_on_inclusion_id"

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
  end

  add_index "inclusions", ["point_id"], :name => "index_inclusions_on_point_id"
  add_index "inclusions", ["user_id"], :name => "index_inclusions_on_user_id"

  create_table "point_links", :force => true do |t|
    t.integer  "point_id"
    t.integer  "proposal_id"
    t.integer  "user_id"
    t.string   "url"
    t.string   "description"
    t.boolean  "approved",    :default => true
    t.datetime "created_at"
    t.datetime "updated_at"
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
  end

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

  create_table "point_versions", :force => true do |t|
    t.integer  "point_id"
    t.integer  "version"
    t.integer  "option_id"
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
    t.boolean  "published",            :default => true
    t.boolean  "hide_name",            :default => false
    t.boolean  "share",                :default => true
    t.boolean  "passes_moderation"
  end

  add_index "point_versions", ["point_id"], :name => "index_point_versions_on_point_id"

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
    t.boolean  "published",            :default => true
    t.boolean  "hide_name",            :default => false
    t.boolean  "share",                :default => true
    t.boolean  "passes_moderation"
    t.integer  "account_id"
  end

  add_index "points", ["is_pro"], :name => "index_points_on_is_pro"
  add_index "points", ["proposal_id"], :name => "index_points_on_option_id"

  create_table "position_versions", :force => true do |t|
    t.integer  "position_id"
    t.integer  "version"
    t.integer  "option_id"
    t.integer  "user_id"
    t.integer  "session_id"
    t.text     "explanation"
    t.float    "stance"
    t.integer  "stance_bucket"
    t.boolean  "published",                         :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.boolean  "notification_includer"
    t.boolean  "notification_proposal_subscriber"
    t.boolean  "notification_statement_subscriber"
  end

  add_index "position_versions", ["position_id"], :name => "index_position_versions_on_position_id"

  create_table "positions", :force => true do |t|
    t.integer  "proposal_id"
    t.integer  "user_id"
    t.integer  "session_id"
    t.text     "explanation"
    t.float    "stance"
    t.integer  "stance_bucket"
    t.boolean  "published",                         :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.integer  "version"
    t.boolean  "notification_includer"
    t.boolean  "notification_proposal_subscriber"
    t.boolean  "notification_statement_subscriber"
    t.integer  "account_id"
  end

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
    t.text     "long_description",           :limit => 2147483647
    t.text     "additional_details",         :limit => 2147483647
    t.string   "poles"
    t.string   "slider_prompt"
    t.string   "considerations_prompt"
    t.string   "statement_prompt"
    t.string   "headers"
    t.string   "entity"
    t.string   "discussion_mode"
    t.boolean  "enable_position_statement"
    t.integer  "account_id"
    t.string   "session_id"
    t.boolean  "require_login",                                    :default => false
    t.boolean  "email_creator_per_position",                       :default => false
    t.string   "long_id"
    t.string   "admin_id"
    t.integer  "user_id"
  end

  add_index "proposals", ["admin_id"], :name => "index_proposals_on_admin_id", :unique => true
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
    t.boolean  "active",     :default => true
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "reflect_bullets", :force => true do |t|
    t.integer  "comment_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "reflect_highlights", :force => true do |t|
    t.integer  "bullet_id"
    t.integer  "bullet_rev"
    t.string   "element_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

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
  end

  create_table "reflect_responses", :force => true do |t|
    t.integer  "bullet_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "study_data", :force => true do |t|
    t.integer  "proposal_id"
    t.integer  "user_id"
    t.integer  "position_id"
    t.integer  "point_id"
    t.integer  "category"
    t.integer  "session_id"
    t.text     "detail1"
    t.text     "detail2"
    t.integer  "ival"
    t.float    "fval"
    t.boolean  "bval"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.string   "email",                                 :default => ""
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
    t.boolean  "notification_commenter",                :default => true
    t.boolean  "notification_author",                   :default => true
    t.boolean  "notification_reflector",                :default => true
    t.boolean  "notification_responder",                :default => true
    t.string   "unconfirmed_email"
    t.datetime "reset_password_sent_at"
  end

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
