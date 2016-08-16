class AddLangToSubdomain < ActiveRecord::Migration
  def change
    add_column :subdomains, :lang, :string, :default => 'en'
  end
end
