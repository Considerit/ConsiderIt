class CreateDomainMaps < ActiveRecord::Migration
  def self.up
    create_table :domain_maps do |t|
      t.integer :identifier
      t.integer :option_id
    end
    add_index :domain_maps, :identifier
  end

  def self.down
    drop_table :domain_maps
  end
end
