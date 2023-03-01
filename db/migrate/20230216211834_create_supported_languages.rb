class CreateSupportedLanguages < ActiveRecord::Migration[6.1]
  def change
    create_table :languages_supported do |t|
      t.string "lang_code"
      t.string "name"
      t.timestamps
    end
  end
end
