class AddCustomUrlToSubdomains < ActiveRecord::Migration[6.1]
  def change
    add_column :subdomains, :custom_url, :string, default: nil
  end
end
