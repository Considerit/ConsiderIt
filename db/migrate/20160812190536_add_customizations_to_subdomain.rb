class AddCustomizationsToSubdomain < ActiveRecord::Migration[5.2]
  def change
    add_column :subdomains, :customizations, :text, :limit => 6553600

  end
end
