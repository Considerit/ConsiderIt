class MakePointsVersionedAndParanoid < ActiveRecord::Migration
  def self.up
    add_column :points, :deleted_at, :timestamp
    Point.create_versioned_table
  end

  def self.down
    Point.drop_versioned_table
    remove_column :points, :deleted_at
  end
end
