class AddUsersToClaims < ActiveRecord::Migration
  def change
    add_column :claims, :creator, :integer 
    add_column :claims, :approver, :integer
  end
end
