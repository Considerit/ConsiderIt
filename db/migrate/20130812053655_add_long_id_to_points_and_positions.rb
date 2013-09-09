class AddLongIdToPointsAndPositions < ActiveRecord::Migration
  def change
    add_column :positions, :long_id, :string    
    add_column :points, :long_id, :string    
  end
end
