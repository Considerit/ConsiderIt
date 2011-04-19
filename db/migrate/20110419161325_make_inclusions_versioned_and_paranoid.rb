class MakeInclusionsVersionedAndParanoid < ActiveRecord::Migration
  def self.up
    Inclusion.create_versioned_table
    add_column :inclusions, :deleted_at, :timestamp
    
  end

  def self.down
    Inclusion.drop_versioned_table
    remove_column :inclusions, :deleted_at    
  end
end
