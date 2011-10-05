class AddModeration < ActiveRecord::Migration
  def self.up
    add_column :comments, :passes_moderation, :boolean, :null => true
    add_column :points, :passes_moderation, :boolean, :null => true
  end

  def self.down
    remove_column :comments, :passes_moderation
    remove_column :points, :passes_moderation    
  end
end
