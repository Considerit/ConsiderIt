class AddDomainToUser < ActiveRecord::Migration
  def self.up
    remove_column :users, :zip
    add_column :users, :domain_id, :integer    
  end

  def self.down
    add_column :users, :zip, :integer
    remove_column :users, :domain_id      
  end
end
