class AddJsonFieldToProposals < ActiveRecord::Migration
  def change
    add_column :proposals, :json, :text, :limit => 4294967    
  end
end
