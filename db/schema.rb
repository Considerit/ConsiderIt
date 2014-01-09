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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20131210223146) do

  create_table "accounts", force: true do |t|
    t.string   "identifier"
    t.string   "theme"
    t.datetime "created_at",                                               null: false
    t.datetime "updated_at",                                               null: false
    t.string   "app_title"
    t.string   "contact_email"
    t.string   "socmedia_facebook_page"
    t.string   "socmedia_twitter_account"
    t.string   "analytics_google"
    t.boolean  "app_require_registration_for_perspective", default: false
    t.string   "socmedia_facebook_client"
    t.string   "socmedia_facebook_secret"
    t.string   "socmedia_twitter_consumer_key"
    t.string   "socmedia_twitter_consumer_secret"
    t.string   "socmedia_twitter_oauth_token"
    t.string   "socmedia_twitter_oauth_token_secret"
    t.boolean  "requires_civility_pledge_on_registration", default: false
    t.integer  "followable_last_notification_milestone"
    t.datetime "followable_last_notification"
    t.string   "default_hashtags"
    t.boolean  "tweet_notifications",                      default: false
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
    t.boolean  "enable_moderation",                        default: false
    t.boolean  "single_page",                              default: false
    t.boolean  "assessment_enabled",                       default: false
    t.integer  "managing_account_id"
    t.text     "header_text"
    t.text     "header_details_text"
    t.boolean  "enable_user_conversations",                default: false
    t.integer  "moderate_points_mode",                     default: 0
    t.integer  "moderate_comments_mode",                   default: 0
    t.integer  "moderate_proposals_mode",                  default: 0
    t.string   "homepage_pic_file_name"
    t.string   "homepage_pic_content_type"
    t.integer  "homepage_pic_file_size"
    t.datetime "homepage_pic_updated_at"
    t.string   "homepage_pic_remote_url"
    t.string   "project_url"
    t.boolean  "enable_hibernation",                       default: false
    t.boolean  "enable_sharing",                           default: false
    t.string   "hibernation_message"
  end

  add_index "accounts", ["identifier"], name: "by_identifier", length: {"identifier"=>10}, using: :btree

  create_table "activities", force: true do |t|
    t.string   "action_type"
    t.integer  "action_id",   null: false
    t.integer  "account_id",  null: false
    t.integer  "user_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "activities", ["account_id"], name: "index_activities_on_account_id", using: :btree

  create_table "assessments", force: true do |t|
    t.integer  "user_id"
    t.integer  "account_id"
    t.integer  "assessable_id"
    t.string   "assessable_type"
    t.boolean  "qualifies"
    t.string   "qualifies_reason"
    t.integer  "verdict_id"
    t.boolean  "complete",         default: false
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",                       null: false
    t.boolean  "reviewable",       default: false
    t.datetime "published_at"
    t.text     "notes"
  end

  create_table "claims", force: true do |t|
    t.integer  "assessment_id"
    t.integer  "account_id"
    t.text     "result"
    t.text     "claim_restatement"
    t.integer  "verdict_id"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.text     "notes"
    t.integer  "creator"
    t.integer  "approver"
  end

  create_table "comments", force: true do |t|
    t.integer  "commentable_id",                         default: 0
    t.string   "commentable_type"
    t.string   "title"
    t.text     "body"
    t.string   "subject"
    t.integer  "user_id",                                default: 0, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "account_id"
    t.integer  "followable_last_notification_milestone", default: 0
    t.datetime "followable_last_notification"
    t.integer  "moderation_status"
    t.integer  "thanks_count",                           default: 0
  end

  add_index "comments", ["account_id", "commentable_id", "commentable_type", "moderation_status"], name: "select_comments", using: :btree
  add_index "comments", ["account_id", "commentable_id", "commentable_type"], name: "select_comments_on_commentable", using: :btree
  add_index "comments", ["account_id"], name: "index_comments_on_account_id", using: :btree
  add_index "comments", ["commentable_id"], name: "index_comments_on_commentable_id", using: :btree
  add_index "comments", ["user_id"], name: "index_comments_on_user_id", using: :btree

  create_table "delayed_jobs", force: true do |t|
    t.integer  "priority",   default: 0
    t.integer  "attempts",   default: 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree

  create_table "emails", force: true do |t|
    t.string   "from_address"
    t.string   "reply_to_address"
    t.string   "subject"
    t.text     "to_address"
    t.text     "cc_address"
    t.text     "bcc_address"
    t.text     "content"
    t.datetime "sent_at"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
  end

  create_table "follows", force: true do |t|
    t.integer  "user_id"
    t.integer  "followable_id"
    t.string   "followable_type"
    t.boolean  "follow",          default: true
    t.boolean  "explicit",        default: false
    t.integer  "account_id"
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
  end

  create_table "inclusions", force: true do |t|
    t.integer  "proposal_id"
    t.integer  "position_id"
    t.integer  "point_id"
    t.integer  "user_id"
    t.integer  "session_id"
    t.boolean  "included_as_pro"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "account_id"
  end

  add_index "inclusions", ["account_id"], name: "index_inclusions_on_account_id", using: :btree
  add_index "inclusions", ["point_id"], name: "index_inclusions_on_point_id", using: :btree
  add_index "inclusions", ["user_id"], name: "index_inclusions_on_user_id", using: :btree

  create_table "moderations", force: true do |t|
    t.integer  "user_id"
    t.integer  "moderatable_id"
    t.string   "moderatable_type"
    t.integer  "status"
    t.datetime "created_at",                                    null: false
    t.datetime "updated_at",                                    null: false
    t.integer  "account_id"
    t.boolean  "updated_since_last_evaluation", default: false
    t.boolean  "notification_sent",             default: false
  end

  create_table "page_views", force: true do |t|
    t.integer  "user_id"
    t.integer  "account_id"
    t.text     "referer"
    t.string   "session"
    t.string   "user_agent"
    t.string   "ip_address"
    t.datetime "created_at"
    t.string   "url"
  end

  create_table "point_listings", force: true do |t|
    t.integer  "proposal_id"
    t.integer  "position_id"
    t.integer  "point_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "account_id"
    t.integer  "count",       default: 1
  end

  add_index "point_listings", ["account_id"], name: "index_point_listings_on_account_id", using: :btree
  add_index "point_listings", ["point_id"], name: "index_point_listings_on_point_id", using: :btree
  add_index "point_listings", ["position_id"], name: "index_point_listings_on_position_id", using: :btree
  add_index "point_listings", ["user_id", "point_id"], name: "index_point_listings_on_user_id_and_point_id", unique: true, using: :btree

  create_table "points", force: true do |t|
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
    t.boolean  "published",                              default: true
    t.boolean  "hide_name",                              default: false
    t.boolean  "share",                                  default: true
    t.integer  "account_id"
    t.integer  "followable_last_notification_milestone"
    t.datetime "followable_last_notification"
    t.integer  "comment_count",                          default: 0
    t.integer  "point_link_count",                       default: 0
    t.text     "includers"
    t.float    "divisiveness"
    t.integer  "moderation_status"
    t.string   "long_id"
  end

  add_index "points", ["account_id", "proposal_id", "id", "is_pro"], name: "select_included_points", using: :btree
  add_index "points", ["account_id", "proposal_id", "published", "id", "is_pro"], name: "select_published_included_points", using: :btree
  add_index "points", ["account_id", "proposal_id", "published", "is_pro"], name: "select_published_pros_or_cons", using: :btree
  add_index "points", ["account_id", "proposal_id", "published", "moderation_status", "is_pro"], name: "select_acceptable_pros_or_cons", using: :btree
  add_index "points", ["account_id"], name: "index_points_on_account_id", using: :btree
  add_index "points", ["is_pro"], name: "index_points_on_is_pro", using: :btree
  add_index "points", ["proposal_id"], name: "index_points_on_option_id", using: :btree

  create_table "positions", force: true do |t|
    t.integer  "proposal_id"
    t.integer  "user_id"
    t.integer  "session_id"
    t.text     "explanation"
    t.float    "stance"
    t.integer  "stance_bucket"
    t.boolean  "published",                              default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "account_id"
    t.integer  "followable_last_notification_milestone"
    t.datetime "followable_last_notification"
    t.text     "point_inclusions"
    t.string   "long_id"
  end

  add_index "positions", ["account_id", "proposal_id", "published"], name: "index_positions_on_account_id_and_proposal_id_and_published", using: :btree
  add_index "positions", ["account_id"], name: "index_positions_on_account_id", using: :btree
  add_index "positions", ["proposal_id"], name: "index_positions_on_option_id", using: :btree
  add_index "positions", ["published"], name: "index_positions_on_published", using: :btree
  add_index "positions", ["stance_bucket"], name: "index_positions_on_stance_bucket", using: :btree
  add_index "positions", ["user_id"], name: "index_positions_on_user_id", using: :btree

  create_table "proposals", force: true do |t|
    t.string   "designator"
    t.string   "category"
    t.string   "name"
    t.string   "short_name"
    t.text     "description"
    t.string   "image"
    t.string   "url1"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "domain"
    t.string   "domain_short"
    t.text     "additional_description1"
    t.text     "additional_description2"
    t.string   "slider_prompt"
    t.string   "considerations_prompt"
    t.string   "statement_prompt"
    t.string   "headers"
    t.string   "entity"
    t.string   "discussion_mode"
    t.boolean  "enable_position_statement"
    t.integer  "account_id"
    t.string   "session_id"
    t.boolean  "require_login",                                           default: false
    t.boolean  "email_creator_per_position",                              default: false
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
    t.boolean  "active",                                                  default: true
    t.integer  "moderation_status"
    t.integer  "publicity",                                               default: 2
    t.binary   "access_list",                            limit: 16777215
    t.integer  "top_con"
    t.integer  "top_pro"
    t.text     "participants"
    t.boolean  "published",                                               default: false
    t.text     "tags"
    t.boolean  "targettable",                                             default: false
    t.string   "url2"
    t.string   "url3"
    t.text     "additional_description3"
    t.string   "url4"
    t.string   "seo_title"
    t.string   "seo_description"
    t.string   "seo_keywords"
    t.string   "slider_middle"
  end

  add_index "proposals", ["account_id", "active"], name: "select_proposal_by_active", using: :btree
  add_index "proposals", ["account_id", "id"], name: "select_proposal", using: :btree
  add_index "proposals", ["account_id", "long_id"], name: "select_proposal_by_long_id", using: :btree
  add_index "proposals", ["account_id"], name: "index_proposals_on_account_id", using: :btree
  add_index "proposals", ["long_id"], name: "index_proposals_on_long_id", unique: true, using: :btree

  create_table "rails_admin_histories", force: true do |t|
    t.string   "message"
    t.string   "username"
    t.integer  "item"
    t.string   "table"
    t.integer  "month",      limit: 2
    t.integer  "year",       limit: 8
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "rails_admin_histories", ["item", "table", "month", "year"], name: "index_histories_on_item_and_table_and_month_and_year", using: :btree

  create_table "requests", force: true do |t|
    t.integer  "user_id"
    t.integer  "assessment_id"
    t.integer  "account_id"
    t.text     "suggestion"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.integer  "assessable_id"
    t.string   "assessable_type"
  end

  create_table "sessions", force: true do |t|
    t.string   "session_id", null: false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], name: "index_sessions_on_session_id", using: :btree
  add_index "sessions", ["updated_at"], name: "index_sessions_on_updated_at", using: :btree

  create_table "thanks", force: true do |t|
    t.integer  "user_id"
    t.integer  "account_id"
    t.integer  "thankable_id"
    t.string   "thankable_type"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
  end

  create_table "users", force: true do |t|
    t.integer  "account_id"
    t.string   "unique_token"
    t.string   "email"
    t.string   "unconfirmed_email"
    t.string   "encrypted_password",     limit: 128, default: ""
    t.string   "reset_password_token"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                      default: 0
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
    t.boolean  "registration_complete",              default: false
    t.integer  "domain_id"
    t.integer  "roles_mask",                         default: 0
    t.text     "referer"
    t.datetime "reset_password_sent_at"
    t.integer  "metric_influence"
    t.integer  "metric_points"
    t.integer  "metric_comments"
    t.integer  "metric_conversations"
    t.integer  "metric_positions"
    t.text     "b64_thumbnail"
    t.text     "tags"
  end

  add_index "users", ["account_id", "avatar_file_name"], name: "select_user_by_avatar_name", length: {"account_id"=>nil, "avatar_file_name"=>3}, using: :btree
  add_index "users", ["account_id", "id"], name: "select_user_by_account_and_id", using: :btree
  add_index "users", ["account_id"], name: "account_id", using: :btree
  add_index "users", ["account_id"], name: "select_user_by_account", using: :btree
  add_index "users", ["email"], name: "index_users_on_email", using: :btree

  create_table "verdicts", force: true do |t|
    t.string   "short_name"
    t.string   "name"
    t.text     "desc"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.string   "icon_file_name"
    t.string   "icon_content_type"
    t.integer  "icon_file_size"
    t.datetime "icon_updated_at"
    t.integer  "account_id"
  end

  create_table "versions", force: true do |t|
    t.string   "item_type",  null: false
    t.integer  "item_id",    null: false
    t.string   "event",      null: false
    t.string   "whodunnit"
    t.text     "object"
    t.datetime "created_at"
  end

  add_index "versions", ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id", using: :btree

end
