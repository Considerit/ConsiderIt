class MakeInclusionsVersionedAndParanoid < ActiveRecord::Migration
  def self.up
    add_column :inclusions, :deleted_at, :timestamp
    Inclusion.create_versioned_table
    
  end

  def self.down
    Inclusion.drop_versioned_table
    remove_column :inclusions, :deleted_at    
  end
end
