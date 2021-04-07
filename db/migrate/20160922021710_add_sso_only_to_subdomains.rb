class AddSsoOnlyToSubdomains < ActiveRecord::Migration[5.2]
  def change
    add_column :subdomains, :SSO_only, :boolean, :default => false
  end
end
