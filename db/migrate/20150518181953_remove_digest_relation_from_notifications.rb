class RemoveDigestRelationFromNotifications < ActiveRecord::Migration[5.2]
  def change
    remove_column :notifications, :digest_object_relationship
  end
end
