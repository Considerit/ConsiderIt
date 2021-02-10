class ConvertThumbnailToLongtext < ActiveRecord::Migration[5.2]
  def change
    change_column :users, :b64_thumbnail, :text, :limit => 4294967295
  end
end
