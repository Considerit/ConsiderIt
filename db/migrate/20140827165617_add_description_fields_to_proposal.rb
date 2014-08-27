class AddDescriptionFieldsToProposal < ActiveRecord::Migration
  def change
    add_column :proposals, :description_fields, :text, :limit => 655360
    
  end
end
