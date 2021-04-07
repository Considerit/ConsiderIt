class AddJsonFieldToProposals < ActiveRecord::Migration[5.2]
  def change
    add_column :proposals, :json, :text, :limit => 4294967    
  end
end
