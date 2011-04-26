class AddIndexes < ActiveRecord::Migration
  def self.up
    add_index :point_listings, :position_id
    add_index :point_listings, :point_id
    add_index :inclusions, :point_id
    add_index :inclusions, :user_id
    add_index :positions, :stance_bucket
    add_index :positions, :published
    add_index :positions, :option_id
    add_index :positions, :user_id
    add_index :points, :is_pro
    add_index :points, :option_id
    
  end

  def self.down
    remove_index :point_listings, :position_id
    remove_index :point_listings, :point_id
    remove_index :inclusions, :point_id
    remove_index :inclusions, :user_id
    remove_index :positions, :stance_bucket
    remove_index :positions, :published
    remove_index :positions, :option_id
    remove_index :positions, :user_id
    remove_index :points, :is_pro
    remove_index :points, :option_id
  end
end
