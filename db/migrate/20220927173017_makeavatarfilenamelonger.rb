class Makeavatarfilenamelonger < ActiveRecord::Migration[5.2]
  def change
    change_column :users, :avatar_remote_url, :text
  end
end
