class Removessosettings < ActiveRecord::Migration
  def change
    remove_column :subdomains, :SSO_settings
  end
end
