class AddTargettableToProposal < ActiveRecord::Migration
  def change
    add_column :proposals, :targettable, :boolean, :default => false
  end
end
