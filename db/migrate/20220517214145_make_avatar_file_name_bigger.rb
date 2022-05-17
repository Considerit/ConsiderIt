class MakeAvatarFileNameBigger < ActiveRecord::Migration[5.2]
  def change
    remove_index :users, name: "index_users_on_avatar_file_name"
    change_column :users, :avatar_file_name, :string, :limit => 2056
  end
end
