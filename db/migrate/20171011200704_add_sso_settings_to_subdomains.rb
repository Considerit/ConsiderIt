class AddSsoSettingsToSubdomains < ActiveRecord::Migration[5.2]
  def change
    add_column :subdomains, :SSO_settings, :text, :limit => 16.megabytes - 1
  end
end
