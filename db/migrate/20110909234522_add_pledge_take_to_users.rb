class AddPledgeTakeToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :pledge_taken, :boolean, :default => false    
  end

  def self.down
    remove_column :users, :pledge_taken
  end
end
