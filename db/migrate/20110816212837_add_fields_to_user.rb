class AddFieldsToUser < ActiveRecord::Migration
  def self.up

    add_column :users, :avatar_file_name,    :string
    add_column :users, :avatar_content_type, :string
    add_column :users, :avatar_file_size,    :integer
    add_column :users, :avatar_updated_at,   :datetime
    add_column :users, :avatar_remote_url,   :string

    add_column :users, :name, :string
    add_column :users, :zip, :integer
    add_column :users, :bio, :text
    add_column :users, :url, :string

    add_column :users, :facebook_uid, :string
    add_column :users, :google_uid, :string
    add_column :users, :yahoo_uid, :string
    add_column :users, :openid_uid, :string
    add_column :users, :twitter_uid, :string

    add_column :users, :twitter_handle, :string

    remove_column :users, :username

    change_column_null :users, :email, true
    change_column_null :users, :encrypted_password, true

    remove_index :users, :email
    add_index :users, :email, :unique => false

  end

  def self.down
    remove_column :users, :avatar_file_name
    remove_column :users, :avatar_content_type
    remove_column :users, :avatar_file_size
    remove_column :users, :avatar_updated_at
    remove_column :users, :avatar_remote_url

    remove_column :users, :facebook_uid
    remove_column :users, :google_uid
    remove_column :users, :yahoo_uid
    remove_column :users, :openid_uid
    remove_column :users, :twitter_uid
    remove_column :users, :twitter_handle

    remove_column :users, :name
    remove_column :users, :zip
    remove_column :users, :bio
    remove_column :users, :url

    add_column :users, :username, :string    

    change_column_null :users, :email, false
    change_column_null :users, :encrypted_password, false

    #remove_index :users, :email
    #add_index :users, :email, :unique => true

        
  end
end
