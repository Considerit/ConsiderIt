# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2023_01_24_190707) do

  create_table "ahoy_events", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "subdomain_id"
    t.bigint "visit_id"
    t.bigint "user_id"
    t.string "name"
    t.json "properties"
    t.datetime "time"
    t.index ["subdomain_id", "name", "time"], name: "index_ahoy_events_on_subdomain_id_and_name_and_time"
    t.index ["subdomain_id"], name: "index_ahoy_events_on_subdomain_id"
    t.index ["user_id"], name: "index_ahoy_events_on_user_id"
    t.index ["visit_id"], name: "index_ahoy_events_on_visit_id"
  end

  create_table "ahoy_visits", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "subdomain_id"
    t.string "visit_token"
    t.string "visitor_token"
    t.bigint "user_id"
    t.string "ip"
    t.text "user_agent"
    t.text "referrer"
    t.string "referring_domain"
    t.text "landing_page"
    t.string "browser"
    t.string "os"
    t.string "device_type"
    t.string "country"
    t.string "region"
    t.string "city"
    t.float "latitude"
    t.float "longitude"
    t.string "utm_source"
    t.string "utm_medium"
    t.string "utm_term"
    t.string "utm_content"
    t.string "utm_campaign"
    t.string "app_version"
    t.string "os_version"
    t.string "platform"
    t.datetime "started_at"
    t.index ["subdomain_id"], name: "index_ahoy_visits_on_subdomain_id"
    t.index ["user_id"], name: "index_ahoy_visits_on_user_id"
    t.index ["visit_token"], name: "index_ahoy_visits_on_visit_token", unique: true
  end

  create_table "comments", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "commentable_id", default: 0
    t.string "commentable_type", collation: "utf8mb3_general_ci"
    t.text "body", collation: "utf8mb4_0900_ai_ci"
    t.integer "user_id", default: 0, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "subdomain_id"
    t.integer "moderation_status"
    t.integer "point_id"
    t.index ["commentable_id"], name: "index_comments_on_commentable_id"
    t.index ["subdomain_id", "commentable_id", "commentable_type", "moderation_status"], name: "select_comments"
    t.index ["subdomain_id", "commentable_id", "commentable_type"], name: "select_comments_on_commentable"
    t.index ["subdomain_id"], name: "index_comments_on_subdomain_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "datastore", id: false, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "k", null: false
    t.json "v"
    t.index ["k"], name: "index_datastore_on_k", unique: true
  end

  create_table "delayed_jobs", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "priority", default: 0
    t.integer "attempts", default: 0
    t.text "handler", collation: "utf8mb3_general_ci"
    t.text "last_error", collation: "utf8mb3_general_ci"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by", collation: "utf8mb3_general_ci"
    t.string "queue", collation: "utf8mb3_general_ci"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "inclusions", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "proposal_id"
    t.integer "point_id"
    t.integer "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "subdomain_id"
    t.index ["point_id"], name: "index_inclusions_on_point_id"
    t.index ["subdomain_id"], name: "index_inclusions_on_subdomain_id"
    t.index ["user_id"], name: "index_inclusions_on_user_id"
  end

  create_table "logs", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "subdomain_id"
    t.integer "who"
    t.string "what", collation: "utf8mb4_0900_ai_ci"
    t.string "where", collation: "utf8mb4_0900_ai_ci"
    t.datetime "when"
    t.text "details", collation: "utf8mb4_0900_ai_ci"
    t.index ["who"], name: "who_index"
  end

  create_table "moderations", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "user_id"
    t.integer "moderatable_id"
    t.string "moderatable_type", collation: "utf8mb3_general_ci"
    t.integer "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "subdomain_id"
    t.boolean "updated_since_last_evaluation", default: false
    t.boolean "notification_sent", default: false
  end

  create_table "opinions", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "proposal_id"
    t.integer "user_id"
    t.text "explanation", collation: "utf8mb4_0900_ai_ci"
    t.float "stance"
    t.boolean "published", default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "subdomain_id"
    t.json "point_inclusions"
    t.index ["proposal_id"], name: "index_positions_on_option_id"
    t.index ["published"], name: "index_opinions_on_published"
    t.index ["subdomain_id", "proposal_id", "published"], name: "index_opinions_on_subdomain_id_and_proposal_id_and_published"
    t.index ["subdomain_id", "proposal_id", "user_id"], name: "index_opinions_on_subdomain_id_and_proposal_id_and_user_id"
    t.index ["subdomain_id"], name: "index_opinions_on_subdomain_id"
    t.index ["user_id"], name: "index_opinions_on_user_id"
  end

  create_table "points", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "proposal_id"
    t.integer "user_id"
    t.text "nutshell", collation: "utf8mb4_0900_ai_ci"
    t.text "text", collation: "utf8mb4_0900_ai_ci"
    t.boolean "is_pro"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float "score"
    t.float "appeal"
    t.boolean "published", default: true
    t.boolean "hide_name", default: false
    t.integer "subdomain_id"
    t.integer "comment_count", default: 0
    t.json "includers"
    t.integer "moderation_status"
    t.integer "last_inclusion", default: 0
    t.index ["is_pro"], name: "index_points_on_is_pro"
    t.index ["proposal_id"], name: "index_points_on_option_id"
    t.index ["subdomain_id", "proposal_id", "id", "is_pro"], name: "select_included_points"
    t.index ["subdomain_id", "proposal_id", "published", "id", "is_pro"], name: "select_published_included_points"
    t.index ["subdomain_id", "proposal_id", "published", "is_pro"], name: "select_published_pros_or_cons"
    t.index ["subdomain_id", "proposal_id", "published", "moderation_status", "is_pro"], name: "select_acceptable_pros_or_cons"
    t.index ["subdomain_id"], name: "index_points_on_subdomain_id"
  end

  create_table "proposals", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.text "name", collation: "utf8mb4_0900_ai_ci"
    t.text "description", size: :medium
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "subdomain_id"
    t.string "slug", collation: "utf8mb4_0900_ai_ci"
    t.integer "user_id"
    t.boolean "active", default: true
    t.integer "moderation_status"
    t.boolean "published", default: false
    t.boolean "hide_on_homepage", default: false
    t.string "seo_title", collation: "utf8mb4_0900_ai_ci"
    t.string "seo_description", collation: "utf8mb4_0900_ai_ci"
    t.string "seo_keywords", collation: "utf8mb4_0900_ai_ci"
    t.string "cluster", collation: "utf8mb3_unicode_ci"
    t.json "roles"
    t.json "histocache"
    t.json "json"
    t.string "pic_file_name"
    t.string "pic_content_type"
    t.integer "pic_file_size"
    t.datetime "pic_updated_at"
    t.string "banner_file_name"
    t.string "banner_content_type"
    t.integer "banner_file_size"
    t.datetime "banner_updated_at"
    t.index ["subdomain_id", "active"], name: "select_proposal_by_active"
    t.index ["subdomain_id", "id"], name: "select_proposal"
    t.index ["subdomain_id", "slug"], name: "select_proposal_by_long_id"
    t.index ["subdomain_id"], name: "index_proposals_on_subdomain_id"
  end

  create_table "sessions", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "session_id", null: false, collation: "utf8mb3_unicode_ci"
    t.text "data", collation: "utf8mb3_unicode_ci"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["session_id"], name: "index_sessions_on_session_id", unique: true
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "subdomains", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "name", collation: "utf8mb4_0900_ai_ci"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "google_analytics_code", collation: "utf8mb3_general_ci"
    t.string "external_project_url", collation: "utf8mb3_general_ci"
    t.string "about_page_url", collation: "utf8mb3_general_ci"
    t.json "roles"
    t.string "masthead_file_name", collation: "utf8mb3_general_ci"
    t.string "masthead_content_type", collation: "utf8mb3_general_ci"
    t.integer "masthead_file_size"
    t.datetime "masthead_updated_at"
    t.string "masthead_remote_url", collation: "utf8mb3_general_ci"
    t.string "logo_file_name", collation: "utf8mb3_general_ci"
    t.string "logo_content_type", collation: "utf8mb3_general_ci"
    t.integer "logo_file_size"
    t.datetime "logo_updated_at"
    t.string "logo_remote_url", collation: "utf8mb3_general_ci"
    t.integer "plan", default: 0
    t.json "customizations"
    t.string "lang", collation: "utf8mb4_0900_ai_ci"
    t.string "SSO_domain", collation: "utf8mb3_general_ci"
    t.integer "moderation_policy", default: 0
    t.json "digest_triggered_for"
    t.integer "created_by"
    t.index ["created_by"], name: "fk_rails_46999ec1f4"
    t.index ["name"], name: "by_identifier", length: 10
  end

  create_table "users", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "unique_token", collation: "utf8mb3_unicode_ci"
    t.string "email", collation: "utf8mb4_0900_ai_ci"
    t.string "encrypted_password", limit: 128, default: "", collation: "utf8mb3_unicode_ci"
    t.string "reset_password_token", collation: "utf8mb3_unicode_ci"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "avatar_file_name", limit: 2056
    t.string "avatar_content_type", collation: "utf8mb3_unicode_ci"
    t.integer "avatar_file_size"
    t.datetime "avatar_updated_at"
    t.text "avatar_remote_url"
    t.string "name", collation: "utf8mb4_0900_ai_ci"
    t.text "bio", collation: "utf8mb4_0900_ai_ci"
    t.string "url", collation: "utf8mb4_0900_ai_ci"
    t.string "facebook_uid", collation: "utf8mb3_unicode_ci"
    t.string "google_uid", collation: "utf8mb3_unicode_ci"
    t.string "openid_uid", collation: "utf8mb3_unicode_ci"
    t.string "twitter_uid", collation: "utf8mb3_unicode_ci"
    t.string "twitter_handle", collation: "utf8mb3_unicode_ci"
    t.boolean "registered", default: false
    t.text "b64_thumbnail", size: :long
    t.json "tags"
    t.json "active_in"
    t.boolean "super_admin", default: false
    t.boolean "verified", default: false
    t.json "subscriptions"
    t.json "emails"
    t.boolean "complete_profile", default: false
    t.string "lang"
    t.integer "paid_forums", default: 0
    t.index ["email"], name: "index_users_on_email"
    t.index ["registered"], name: "index_users_on_registered"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", length: 3
  end

  add_foreign_key "subdomains", "users", column: "created_by"
end
