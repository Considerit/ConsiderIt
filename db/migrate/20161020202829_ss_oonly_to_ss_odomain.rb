class SsOonlyToSsOdomain < ActiveRecord::Migration[5.2]
  def change
    remove_column :subdomains, :SSO_only
    add_column :subdomains, :SSO_domain, :string, :default => nil
  end
end
