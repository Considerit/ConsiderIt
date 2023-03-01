class CreateLanguageTranslationTable < ActiveRecord::Migration[6.1]
  def change
    create_table :language_translations, id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC" do |t|
      t.text "string_id"
      t.string "lang_code"
      t.integer "subdomain_id", default: nil

      t.text "translation"

      t.boolean "accepted", default: false
      t.datetime "accepted_at", default: nil

      t.integer "user_id"

      t.string "origin_server"

      t.integer "uses_this_period", default: 0
      t.integer "uses_last_period", default: 0

      t.timestamps

      t.index ["accepted", "lang_code", "subdomain_id"], name: "all_accepted_for_lang_with_subdomain"
      t.index ["accepted", "lang_code"], name: "all_accepted_for_lang"

    end
  end
end
