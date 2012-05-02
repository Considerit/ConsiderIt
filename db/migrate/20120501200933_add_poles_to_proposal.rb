class AddPolesToProposal < ActiveRecord::Migration
  def change
    add_column :proposals, :slider_right, :string
    add_column :proposals, :slider_left, :string    
    remove_column :proposals, :poles
  end
end
