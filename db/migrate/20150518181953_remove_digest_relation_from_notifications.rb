class RemoveDigestRelationFromNotifications < ActiveRecord::Migration
  def change
    remove_column :notifications, :digest_object_relationship
  end
end
