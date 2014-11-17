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

ActiveRecord::Schema.define(version: 20141117042504) do

  create_table "assessments", force: true do |t|
    t.integer  "user_id"
    t.integer  "subdomain_id"
    t.integer  "assessable_id"
    t.string   "assessable_type"
    t.integer  "verdict_id"
    t.boolean  "complete",        default: false
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.boolean  "reviewable",      default: false
    t.datetime "published_at"
    t.text     "notes"
  end

  create_table "claims", force: true do |t|
    t.integer  "assessment_id"
    t.integer  "subdomain_id"
    t.text     "result"
    t.text     "claim_restatement"
    t.integer  "verdict_id"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.integer  "creator"
    t.integer  "approver"
  end

  create_table "client_errors", force: true do |t|
    t.text     "trace"
    t.string   "error_type"
    t.string   "line"
    t.string   "message"
    t.integer  "user_id"
    t.string   "session_id"
    t.string   "user_agent"
    t.string   "browser"
    t.string   "version"
    t.string   "platform"
    t.string   "location"
    t.string   "ip"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "comments", force: true do |t|
    t.integer  "commentable_id",    default: 0
    t.string   "commentable_type"
    t.text     "body"
    t.integer  "user_id",           default: 0, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "subdomain_id"
    t.integer  "moderation_status"
    t.integer  "point_id"
  end

  add_index "comments", ["commentable_id"], name: "index_comments_on_commentable_id", using: :btree
  add_index "comments", ["subdomain_id", "commentable_id", "commentable_type", "moderation_status"], name: "select_comments", using: :btree
  add_index "comments", ["subdomain_id", "commentable_id", "commentable_type"], name: "select_comments_on_commentable", using: :btree
  add_index "comments", ["subdomain_id"], name: "index_comments_on_subdomain_id", using: :btree
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
    t.integer  "subdomain_id"
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
  end

  create_table "inclusions", force: true do |t|
    t.integer  "proposal_id"
    t.integer  "point_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "subdomain_id"
  end

  add_index "inclusions", ["point_id"], name: "index_inclusions_on_point_id", using: :btree
  add_index "inclusions", ["subdomain_id"], name: "index_inclusions_on_subdomain_id", using: :btree
  add_index "inclusions", ["user_id"], name: "index_inclusions_on_user_id", using: :btree

  create_table "logs", force: true do |t|
    t.integer  "subdomain_id"
    t.integer  "who"
    t.string   "what"
    t.string   "where"
    t.datetime "when"
    t.text     "details"
  end

  add_index "logs", ["who"], name: "who_index", using: :btree

  create_table "moderations", force: true do |t|
    t.integer  "user_id"
    t.integer  "moderatable_id"
    t.string   "moderatable_type"
    t.integer  "status"
    t.datetime "created_at",                                    null: false
    t.datetime "updated_at",                                    null: false
    t.integer  "subdomain_id"
    t.boolean  "updated_since_last_evaluation", default: false
    t.boolean  "notification_sent",             default: false
  end

  create_table "opinions", force: true do |t|
    t.integer  "proposal_id"
    t.integer  "user_id"
    t.text     "explanation"
    t.float    "stance",           limit: 24
    t.integer  "stance_segment"
    t.boolean  "published",                   default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "subdomain_id"
    t.text     "point_inclusions"
  end

  add_index "opinions", ["proposal_id"], name: "index_positions_on_option_id", using: :btree
  add_index "opinions", ["published"], name: "index_opinions_on_published", using: :btree
  add_index "opinions", ["stance_segment"], name: "index_opinions_on_stance_segment", using: :btree
  add_index "opinions", ["subdomain_id", "proposal_id", "published"], name: "index_opinions_on_subdomain_id_and_proposal_id_and_published", using: :btree
  add_index "opinions", ["subdomain_id"], name: "index_opinions_on_subdomain_id", using: :btree
  add_index "opinions", ["user_id"], name: "index_opinions_on_user_id", using: :btree

  create_table "points", force: true do |t|
    t.integer  "proposal_id"
    t.integer  "user_id"
    t.text     "nutshell"
    t.text     "text"
    t.boolean  "is_pro"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "num_inclusions"
    t.float    "score",             limit: 24
    t.float    "appeal",            limit: 24
    t.boolean  "published",                    default: true
    t.boolean  "hide_name",                    default: false
    t.integer  "subdomain_id"
    t.integer  "comment_count",                default: 0
    t.text     "includers"
    t.integer  "moderation_status"
    t.string   "long_id"
    t.integer  "last_inclusion",               default: 0
  end

  add_index "points", ["is_pro"], name: "index_points_on_is_pro", using: :btree
  add_index "points", ["proposal_id"], name: "index_points_on_option_id", using: :btree
  add_index "points", ["subdomain_id", "proposal_id", "id", "is_pro"], name: "select_included_points", using: :btree
  add_index "points", ["subdomain_id", "proposal_id", "published", "id", "is_pro"], name: "select_published_included_points", using: :btree
  add_index "points", ["subdomain_id", "proposal_id", "published", "is_pro"], name: "select_published_pros_or_cons", using: :btree
  add_index "points", ["subdomain_id", "proposal_id", "published", "moderation_status", "is_pro"], name: "select_acceptable_pros_or_cons", using: :btree
  add_index "points", ["subdomain_id"], name: "index_points_on_subdomain_id", using: :btree

  create_table "proposals", force: true do |t|
    t.string   "designator"
    t.string   "category"
    t.string   "name"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "subdomain_id"
    t.string   "long_id"
    t.integer  "user_id"
    t.float    "trending",                               limit: 24
    t.float    "activity",                               limit: 24
    t.float    "provocative",                            limit: 24
    t.float    "contested",                              limit: 24
    t.integer  "num_points"
    t.integer  "num_pros"
    t.integer  "num_cons"
    t.integer  "num_comments"
    t.integer  "num_inclusions"
    t.integer  "num_perspectives"
    t.integer  "num_supporters"
    t.integer  "num_opposers"
    t.integer  "followable_last_notification_milestone"
    t.datetime "followable_last_notification"
    t.boolean  "active",                                                  default: true
    t.integer  "moderation_status"
    t.integer  "publicity",                                               default: 2
    t.binary   "access_list",                            limit: 16777215
    t.boolean  "published",                                               default: false
    t.boolean  "hide_on_homepage",                                        default: false
    t.string   "seo_title"
    t.string   "seo_description"
    t.string   "seo_keywords"
    t.text     "description_fields",                     limit: 16777215
    t.string   "cluster"
    t.text     "zips"
  end

  add_index "proposals", ["subdomain_id", "active"], name: "select_proposal_by_active", using: :btree
  add_index "proposals", ["subdomain_id", "id"], name: "select_proposal", using: :btree
  add_index "proposals", ["subdomain_id", "long_id"], name: "select_proposal_by_long_id", using: :btree
  add_index "proposals", ["subdomain_id"], name: "index_proposals_on_subdomain_id", using: :btree

  create_table "requests", force: true do |t|
    t.integer  "user_id"
    t.integer  "assessment_id"
    t.integer  "subdomain_id"
    t.text     "suggestion"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.integer  "assessable_id"
    t.string   "assessable_type"
  end

  create_table "subdomains", force: true do |t|
    t.string   "identifier"
    t.datetime "created_at",                                               null: false
    t.datetime "updated_at",                                               null: false
    t.string   "app_title"
    t.string   "contact_email"
    t.string   "analytics_google"
    t.boolean  "requires_civility_pledge_on_registration", default: false
    t.string   "host"
    t.string   "host_with_port"
    t.boolean  "assessment_enabled",                       default: false
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
    t.string   "about_page_url"
    t.text     "roles"
  end

  add_index "subdomains", ["identifier"], name: "by_identifier", length: {"identifier"=>10}, using: :btree

  create_table "users", force: true do |t|
    t.string   "unique_token"
    t.string   "email"
    t.string   "encrypted_password",     limit: 128, default: ""
    t.string   "reset_password_token"
    t.datetime "created_at"
    t.datetime "updated_at"
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
    t.string   "openid_uid"
    t.string   "twitter_uid"
    t.string   "twitter_handle"
    t.boolean  "registration_complete",              default: false
    t.datetime "reset_password_sent_at"
    t.text     "b64_thumbnail"
    t.text     "tags"
    t.text     "active_in"
    t.boolean  "super_admin",                        default: false
    t.boolean  "no_email_notifications",             default: false
  end

  add_index "users", ["avatar_file_name"], name: "index_users_on_avatar_file_name", using: :btree
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
    t.integer  "subdomain_id"
  end

end
