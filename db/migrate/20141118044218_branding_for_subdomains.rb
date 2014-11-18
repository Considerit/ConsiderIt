class BrandingForSubdomains < ActiveRecord::Migration
  def change
    remove_column :subdomains, "homepage_pic_file_name", :string
    remove_column :subdomains, "homepage_pic_content_type", :string
    remove_column :subdomains, "homepage_pic_file_size", :integer
    remove_column :subdomains, "homepage_pic_updated_at", :datetime
    remove_column :subdomains, "homepage_pic_remote_url", :string

    add_column :subdomains, "masthead_file_name", :string
    add_column :subdomains, "masthead_content_type", :string
    add_column :subdomains, "masthead_file_size", :integer
    add_column :subdomains, "masthead_updated_at", :datetime
    add_column :subdomains, "masthead_remote_url", :string

    add_column :subdomains, "logo_file_name", :string
    add_column :subdomains, "logo_content_type", :string
    add_column :subdomains, "logo_file_size", :integer
    add_column :subdomains, "logo_updated_at", :datetime
    add_column :subdomains, "logo_remote_url", :string

    add_column :subdomains, :branding, :text
  end
end
