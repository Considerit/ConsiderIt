class ChangeDomainMap < ActiveRecord::Migration
  def self.up
    remove_column :domain_maps, :identifier
    add_column :domain_maps, :domain_id, :integer
  end

  def self.down
    add_column :domain_maps, :identifier, :integer
    remove_column :domain_maps, :domain_id
  end
end
