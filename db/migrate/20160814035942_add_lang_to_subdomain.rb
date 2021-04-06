class AddLangToSubdomain < ActiveRecord::Migration[5.2]
  def change
    add_column :subdomains, :lang, :string, :default => 'en'
  end
end
