class AddPostAnonymouslyToPoint < ActiveRecord::Migration
  def self.up
    add_column :points, :hide_name, :boolean, :default => false  
    add_column :point_versions, :hide_name, :boolean, :default => false  
       
    add_column :points, :share, :boolean, :default => true    
    add_column :point_versions, :share, :boolean, :default => true    

  end

  def self.down
    remove_column :points, :hide_name 
    remove_column :point_versions, :hide_name 
    remove_column :points, :share      
    remove_column :point_versions, :share
  end
end
