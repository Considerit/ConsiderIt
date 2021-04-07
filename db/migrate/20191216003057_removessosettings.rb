class Removessosettings < ActiveRecord::Migration[5.2]
  def change
    remove_column :subdomains, :SSO_settings
  end
end
