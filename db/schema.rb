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

ActiveRecord::Schema.define(version: 20150702151911) do

  create_table "assessments", force: :cascade do |t|
    t.integer  "user_id",         limit: 4
    t.integer  "subdomain_id",    limit: 4
    t.integer  "assessable_id",   limit: 4
    t.string   "assessable_type", limit: 255
    t.integer  "verdict_id",      limit: 4
    t.boolean  "complete",                      default: false
    t.datetime "created_at",                                    null: false
    t.datetime "updated_at",                                    null: false
    t.boolean  "reviewable",                    default: false
    t.datetime "published_at"
    t.text     "notes",           limit: 65535
  end

  create_table "claims", force: :cascade do |t|
    t.integer  "assessment_id",     limit: 4
    t.integer  "subdomain_id",      limit: 4
    t.text     "result",            limit: 65535
    t.text     "claim_restatement", limit: 65535
    t.integer  "verdict_id",        limit: 4
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.integer  "creator",           limit: 4
    t.integer  "approver",          limit: 4
  end

  create_table "client_errors", force: :cascade do |t|
    t.text     "trace",      limit: 65535
    t.string   "error_type", limit: 255
    t.string   "line",       limit: 255
    t.string   "message",    limit: 255
    t.integer  "user_id",    limit: 4
    t.string   "session_id", limit: 255
    t.string   "user_agent", limit: 255
    t.string   "browser",    limit: 255
    t.string   "version",    limit: 255
    t.string   "platform",   limit: 255
    t.string   "location",   limit: 255
    t.string   "ip",         limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "comments", force: :cascade do |t|
    t.integer  "commentable_id",    limit: 4,     default: 0
    t.string   "commentable_type",  limit: 255
    t.text     "body",              limit: 65535
    t.integer  "user_id",           limit: 4,     default: 0, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "subdomain_id",      limit: 4
    t.integer  "moderation_status", limit: 4
    t.integer  "point_id",          limit: 4
  end

  add_index "comments", ["commentable_id"], name: "index_comments_on_commentable_id", using: :btree
  add_index "comments", ["subdomain_id", "commentable_id", "commentable_type", "moderation_status"], name: "select_comments", using: :btree
  add_index "comments", ["subdomain_id", "commentable_id", "commentable_type"], name: "select_comments_on_commentable", using: :btree
  add_index "comments", ["subdomain_id"], name: "index_comments_on_subdomain_id", using: :btree
  add_index "comments", ["user_id"], name: "index_comments_on_user_id", using: :btree

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",   limit: 4,     default: 0
    t.integer  "attempts",   limit: 4,     default: 0
    t.text     "handler",    limit: 65535
    t.text     "last_error", limit: 65535
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by",  limit: 255
    t.string   "queue",      limit: 255
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree

  create_table "emails", force: :cascade do |t|
    t.string   "from_address",     limit: 255
    t.string   "reply_to_address", limit: 255
    t.string   "subject",          limit: 255
    t.text     "to_address",       limit: 65535
    t.text     "cc_address",       limit: 65535
    t.text     "bcc_address",      limit: 65535
    t.text     "content",          limit: 65535
    t.datetime "sent_at"
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
  end

  create_table "follows", force: :cascade do |t|
    t.integer  "user_id",         limit: 4
    t.integer  "followable_id",   limit: 4
    t.string   "followable_type", limit: 255
    t.boolean  "follow",                      default: true
    t.boolean  "explicit",                    default: false
    t.integer  "subdomain_id",    limit: 4
    t.datetime "created_at",                                  null: false
    t.datetime "updated_at",                                  null: false
  end

  create_table "inclusions", force: :cascade do |t|
    t.integer  "proposal_id",  limit: 4
    t.integer  "point_id",     limit: 4
    t.integer  "user_id",      limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "subdomain_id", limit: 4
  end

  add_index "inclusions", ["point_id"], name: "index_inclusions_on_point_id", using: :btree
  add_index "inclusions", ["subdomain_id"], name: "index_inclusions_on_subdomain_id", using: :btree
  add_index "inclusions", ["user_id"], name: "index_inclusions_on_user_id", using: :btree

  create_table "logs", force: :cascade do |t|
    t.integer  "subdomain_id", limit: 4
    t.integer  "who",          limit: 4
    t.string   "what",         limit: 255
    t.string   "where",        limit: 255
    t.datetime "when"
    t.text     "details",      limit: 65535
  end

  add_index "logs", ["who"], name: "who_index", using: :btree

  create_table "moderations", force: :cascade do |t|
    t.integer  "user_id",                       limit: 4
    t.integer  "moderatable_id",                limit: 4
    t.string   "moderatable_type",              limit: 255
    t.integer  "status",                        limit: 4
    t.datetime "created_at",                                                null: false
    t.datetime "updated_at",                                                null: false
    t.integer  "subdomain_id",                  limit: 4
    t.boolean  "updated_since_last_evaluation",             default: false
    t.boolean  "notification_sent",                         default: false
  end

  create_table "notifications", force: :cascade do |t|
    t.integer  "subdomain_id",              limit: 4
    t.integer  "user_id",                   limit: 4
    t.string   "digest_object_type",        limit: 255
    t.integer  "digest_object_id",          limit: 4
    t.string   "event_object_type",         limit: 255
    t.integer  "event_object_id",           limit: 4
    t.string   "event_object_relationship", limit: 255
    t.string   "event_type",                limit: 255
    t.boolean  "sent_email"
    t.datetime "read_at"
    t.datetime "created_at"
  end

  create_table "opinions", force: :cascade do |t|
    t.integer  "proposal_id",      limit: 4
    t.integer  "user_id",          limit: 4
    t.text     "explanation",      limit: 65535
    t.float    "stance",           limit: 24
    t.integer  "stance_segment",   limit: 4
    t.boolean  "published",                      default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "subdomain_id",     limit: 4
    t.text     "point_inclusions", limit: 65535
  end

  add_index "opinions", ["proposal_id"], name: "index_positions_on_option_id", using: :btree
  add_index "opinions", ["published"], name: "index_opinions_on_published", using: :btree
  add_index "opinions", ["stance_segment"], name: "index_opinions_on_stance_segment", using: :btree
  add_index "opinions", ["subdomain_id", "proposal_id", "published"], name: "index_opinions_on_subdomain_id_and_proposal_id_and_published", using: :btree
  add_index "opinions", ["subdomain_id"], name: "index_opinions_on_subdomain_id", using: :btree
  add_index "opinions", ["user_id"], name: "index_opinions_on_user_id", using: :btree

  create_table "points", force: :cascade do |t|
    t.integer  "proposal_id",       limit: 4
    t.integer  "user_id",           limit: 4
    t.text     "nutshell",          limit: 65535
    t.text     "text",              limit: 65535
    t.boolean  "is_pro"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "num_inclusions",    limit: 4
    t.float    "score",             limit: 24
    t.float    "appeal",            limit: 24
    t.boolean  "published",                       default: true
    t.boolean  "hide_name",                       default: false
    t.integer  "subdomain_id",      limit: 4
    t.integer  "comment_count",     limit: 4,     default: 0
    t.text     "includers",         limit: 65535
    t.integer  "moderation_status", limit: 4
    t.integer  "last_inclusion",    limit: 4,     default: 0
  end

  add_index "points", ["is_pro"], name: "index_points_on_is_pro", using: :btree
  add_index "points", ["proposal_id"], name: "index_points_on_option_id", using: :btree
  add_index "points", ["subdomain_id", "proposal_id", "id", "is_pro"], name: "select_included_points", using: :btree
  add_index "points", ["subdomain_id", "proposal_id", "published", "id", "is_pro"], name: "select_published_included_points", using: :btree
  add_index "points", ["subdomain_id", "proposal_id", "published", "is_pro"], name: "select_published_pros_or_cons", using: :btree
  add_index "points", ["subdomain_id", "proposal_id", "published", "moderation_status", "is_pro"], name: "select_acceptable_pros_or_cons", using: :btree
  add_index "points", ["subdomain_id"], name: "index_points_on_subdomain_id", using: :btree

  create_table "proposals", force: :cascade do |t|
    t.string   "designator",                             limit: 255
    t.string   "category",                               limit: 255
    t.string   "name",                                   limit: 255
    t.text     "description",                            limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "subdomain_id",                           limit: 4
    t.string   "slug",                                   limit: 255
    t.integer  "user_id",                                limit: 4
    t.float    "trending",                               limit: 24
    t.float    "activity",                               limit: 24
    t.float    "provocative",                            limit: 24
    t.float    "contested",                              limit: 24
    t.integer  "num_points",                             limit: 4
    t.integer  "num_pros",                               limit: 4
    t.integer  "num_cons",                               limit: 4
    t.integer  "num_comments",                           limit: 4
    t.integer  "num_inclusions",                         limit: 4
    t.integer  "num_perspectives",                       limit: 4
    t.integer  "num_supporters",                         limit: 4
    t.integer  "num_opposers",                           limit: 4
    t.integer  "followable_last_notification_milestone", limit: 4
    t.datetime "followable_last_notification"
    t.boolean  "active",                                                  default: true
    t.integer  "moderation_status",                      limit: 4
    t.integer  "publicity",                              limit: 4,        default: 2
    t.binary   "access_list",                            limit: 16777215
    t.boolean  "published",                                               default: false
    t.boolean  "hide_on_homepage",                                        default: false
    t.string   "seo_title",                              limit: 255
    t.string   "seo_description",                        limit: 255
    t.string   "seo_keywords",                           limit: 255
    t.text     "description_fields",                     limit: 16777215
    t.string   "cluster",                                limit: 255
    t.text     "zips",                                   limit: 65535
    t.text     "roles",                                  limit: 65535
  end

  add_index "proposals", ["subdomain_id", "active"], name: "select_proposal_by_active", using: :btree
  add_index "proposals", ["subdomain_id", "id"], name: "select_proposal", using: :btree
  add_index "proposals", ["subdomain_id", "slug"], name: "select_proposal_by_long_id", using: :btree
  add_index "proposals", ["subdomain_id"], name: "index_proposals_on_subdomain_id", using: :btree

  create_table "requests", force: :cascade do |t|
    t.integer  "user_id",         limit: 4
    t.integer  "assessment_id",   limit: 4
    t.integer  "subdomain_id",    limit: 4
    t.text     "suggestion",      limit: 65535
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.integer  "assessable_id",   limit: 4
    t.string   "assessable_type", limit: 255
  end

  create_table "sessions", force: :cascade do |t|
    t.string   "session_id", limit: 255,   null: false
    t.text     "data",       limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], name: "index_sessions_on_session_id", unique: true, using: :btree
  add_index "sessions", ["updated_at"], name: "index_sessions_on_updated_at", using: :btree

  create_table "subdomains", force: :cascade do |t|
    t.string   "name",                       limit: 255
    t.datetime "created_at",                                               null: false
    t.datetime "updated_at",                                               null: false
    t.string   "app_title",                  limit: 255
    t.string   "notifications_sender_email", limit: 255
    t.string   "google_analytics_code",      limit: 255
    t.boolean  "has_civility_pledge",                      default: false
    t.string   "host",                       limit: 255
    t.string   "host_with_port",             limit: 255
    t.boolean  "assessment_enabled",                       default: false
    t.integer  "moderate_points_mode",       limit: 4,     default: 0
    t.integer  "moderate_comments_mode",     limit: 4,     default: 0
    t.integer  "moderate_proposals_mode",    limit: 4,     default: 0
    t.string   "external_project_url",       limit: 255
    t.string   "about_page_url",             limit: 255
    t.text     "roles",                      limit: 65535
    t.string   "masthead_file_name",         limit: 255
    t.string   "masthead_content_type",      limit: 255
    t.integer  "masthead_file_size",         limit: 4
    t.datetime "masthead_updated_at"
    t.string   "masthead_remote_url",        limit: 255
    t.string   "logo_file_name",             limit: 255
    t.string   "logo_content_type",          limit: 255
    t.integer  "logo_file_size",             limit: 4
    t.datetime "logo_updated_at"
    t.string   "logo_remote_url",            limit: 255
    t.text     "branding",                   limit: 65535
  end

  add_index "subdomains", ["name"], name: "by_identifier", length: {"name"=>10}, using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "unique_token",           limit: 255
    t.string   "email",                  limit: 255
    t.string   "encrypted_password",     limit: 128,   default: ""
    t.string   "reset_password_token",   limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "avatar_file_name",       limit: 255
    t.string   "avatar_content_type",    limit: 255
    t.integer  "avatar_file_size",       limit: 4
    t.datetime "avatar_updated_at"
    t.string   "avatar_remote_url",      limit: 255
    t.string   "name",                   limit: 255
    t.text     "bio",                    limit: 65535
    t.string   "url",                    limit: 255
    t.string   "facebook_uid",           limit: 255
    t.string   "google_uid",             limit: 255
    t.string   "openid_uid",             limit: 255
    t.string   "twitter_uid",            limit: 255
    t.string   "twitter_handle",         limit: 255
    t.boolean  "registered",                           default: false
    t.datetime "reset_password_sent_at"
    t.text     "b64_thumbnail",          limit: 65535
    t.text     "tags",                   limit: 65535
    t.text     "active_in",              limit: 65535
    t.boolean  "super_admin",                          default: false
    t.boolean  "no_email_notifications",               default: false
    t.boolean  "verified",                             default: false
    t.text     "groups",                 limit: 65535
    t.text     "subscriptions",          limit: 65535
    t.text     "emails",                 limit: 65535
    t.boolean  "complete_profile",                     default: false
  end

  add_index "users", ["avatar_file_name"], name: "index_users_on_avatar_file_name", using: :btree
  add_index "users", ["email"], name: "index_users_on_email", using: :btree

  create_table "verdicts", force: :cascade do |t|
    t.string   "short_name",        limit: 255
    t.string   "name",              limit: 255
    t.text     "desc",              limit: 65535
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.string   "icon_file_name",    limit: 255
    t.string   "icon_content_type", limit: 255
    t.integer  "icon_file_size",    limit: 4
    t.datetime "icon_updated_at"
    t.integer  "subdomain_id",      limit: 4
  end

end
