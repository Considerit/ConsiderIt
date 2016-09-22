class AddSsoOnlyToSubdomains < ActiveRecord::Migration
  def change
    add_column :subdomains, :SSO_only, :boolean, :default => false
  end
end
