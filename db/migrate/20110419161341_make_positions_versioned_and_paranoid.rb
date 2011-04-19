class MakePositionsVersionedAndParanoid < ActiveRecord::Migration
  def self.up
    add_column :positions, :deleted_at, :timestamp
    Position.create_versioned_table
    
  end

  def self.down
    Position.drop_versioned_table
    remove_column :positions, :deleted_at
    
  end
end
