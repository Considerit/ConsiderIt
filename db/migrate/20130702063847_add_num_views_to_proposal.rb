class AddNumViewsToProposal < ActiveRecord::Migration
  def change
    begin
      add_column :proposals, :num_views, :integer, :default => 0
    rescue
    end
  end
end
