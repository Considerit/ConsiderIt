class AddStartEndCloseToProposals < ActiveRecord::Migration
  def change
    add_column :proposals, :start_date, :datetime
    add_column :proposals, :end_date, :datetime
    add_column :proposals, :active, :boolean, :default => true
  end
end
