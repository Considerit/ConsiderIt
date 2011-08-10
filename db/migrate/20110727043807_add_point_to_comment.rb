class AddPointToComment < ActiveRecord::Migration
  def self.up
    add_column :comments, :point_id, :integer
    add_column :comments, :option_id, :integer
  end  

  def self.down
    remove_column :comments, :point_id
    remove_column :comments, :option_id 
  end
end