class AddHomepagePicToAccount < ActiveRecord::Migration
  def change
    add_column :accounts, :homepage_pic_file_name,    :string
    add_column :accounts, :homepage_pic_content_type, :string
    add_column :accounts, :homepage_pic_file_size,    :integer
    add_column :accounts, :homepage_pic_updated_at,   :datetime
    add_column :accounts, :homepage_pic_remote_url,   :string    
  end
end
