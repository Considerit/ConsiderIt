class AddSsoSettingsToSubdomains < ActiveRecord::Migration
  def change
    add_column :subdomains, :SSO_settings, :text, :limit => 16.megabytes - 1
  end
end
