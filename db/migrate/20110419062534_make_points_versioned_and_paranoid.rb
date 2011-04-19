class MadePointsVersionedAndParanoid < ActiveRecord::Migration
  def self.up
    Point.create_versioned_table
    add_column :points, :deleted_at, :timestamp
  end

  def self.down
    Point.drop_versioned_table
    remove_column :points, :deleted_at
  end
end
