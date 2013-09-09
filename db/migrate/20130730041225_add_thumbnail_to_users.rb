class AddThumbnailToUsers < ActiveRecord::Migration
  def change
    add_column :users, :b64_thumbnail, :text
  end
end
