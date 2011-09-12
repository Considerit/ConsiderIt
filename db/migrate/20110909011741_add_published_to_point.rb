class AddPublishedToPoint < ActiveRecord::Migration
  def self.up
    add_column :points, :published, :boolean, :default => true
    add_column :point_versions, :published, :boolean, :default => true
  end

  def self.down
    remove_column :points, :published
    remove_column :point_versions, :published
  end
end
