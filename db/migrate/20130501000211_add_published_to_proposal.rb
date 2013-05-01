class AddPublishedToProposal < ActiveRecord::Migration
  def change
    add_column :proposals, :published, :boolean, :default => false
  end
end
