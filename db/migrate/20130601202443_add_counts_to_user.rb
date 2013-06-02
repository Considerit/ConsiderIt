class AddCountsToUser < ActiveRecord::Migration
  def change
    add_column :users, :metric_influence, :integer
    add_column :users, :metric_points, :integer
    add_column :users, :metric_comments, :integer
    add_column :users, :metric_conversations, :integer        
    add_column :users, :metric_positions, :integer        

  end
end
