class AddCustomizationsToSubdomain < ActiveRecord::Migration
  def change
    add_column :subdomains, :customizations, :text, :limit => 6553600

  end
end
