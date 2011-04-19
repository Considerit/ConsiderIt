class MakePositionsVersionedAndParanoid < ActiveRecord::Migration
  def self.up
    Position.create_versioned_table
    add_column :positions, :deleted_at, :timestamp
    
  end

  def self.down
    Position.drop_versioned_table
    remove_column :positions, :deleted_at
    
  end
end
