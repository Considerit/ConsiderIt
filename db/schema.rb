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

ActiveRecord::Schema.define(:version => 20110727043807) do

  create_table "comments", :force => true do |t|
    t.integer  "commentable_id",   :default => 0
    t.string   "commentable_type", :default => ""
    t.string   "title",            :default => ""
    t.text     "body"
    t.string   "subject",          :default => ""
    t.integer  "user_id",          :default => 0,  :null => false
    t.integer  "parent_id"
    t.integer  "lft"
    t.integer  "rgt"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "point_id"
  end

  add_index "comments", ["commentable_id"], :name => "index_comments_on_commentable_id"
  add_index "comments", ["user_id"], :name => "index_comments_on_user_id"

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
    t.integer  "option_id"
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

  create_table "options", :force => true do |t|
    t.string   "designator"
    t.string   "category"
    t.string   "name"
    t.string   "short_name"
    t.text     "description"
    t.string   "image"
    t.string   "url"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "point_listings", :force => true do |t|
    t.integer  "option_id"
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
    t.integer  "option_id"
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
  end

  add_index "point_versions", ["point_id"], :name => "index_point_versions_on_point_id"

  create_table "points", :force => true do |t|
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
    t.integer  "version"
  end

  add_index "points", ["is_pro"], :name => "index_points_on_is_pro"
  add_index "points", ["option_id"], :name => "index_points_on_option_id"

  create_table "position_versions", :force => true do |t|
    t.integer  "position_id"
    t.integer  "version"
    t.integer  "option_id"
    t.integer  "user_id"
    t.integer  "session_id"
    t.text     "explanation"
    t.float    "stance"
    t.integer  "stance_bucket"
    t.boolean  "published",     :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  add_index "position_versions", ["position_id"], :name => "index_position_versions_on_position_id"

  create_table "positions", :force => true do |t|
    t.integer  "option_id"
    t.integer  "user_id"
    t.integer  "session_id"
    t.text     "explanation"
    t.float    "stance"
    t.integer  "stance_bucket"
    t.boolean  "published",     :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.integer  "version"
  end

  add_index "positions", ["option_id"], :name => "index_positions_on_option_id"
  add_index "positions", ["published"], :name => "index_positions_on_published"
  add_index "positions", ["stance_bucket"], :name => "index_positions_on_stance_bucket"
  add_index "positions", ["user_id"], :name => "index_positions_on_user_id"

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

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "users", :force => true do |t|
    t.string   "email",                               :default => "",    :null => false
    t.string   "encrypted_password",   :limit => 128, :default => "",    :null => false
    t.string   "reset_password_token"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                       :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "username"
    t.text     "sessions"
    t.boolean  "admin",                               :default => false
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

end
