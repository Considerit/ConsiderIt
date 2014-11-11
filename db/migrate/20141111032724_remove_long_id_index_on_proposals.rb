class RemoveLongIdIndexOnProposals < ActiveRecord::Migration
  def change
    remove_index :proposals, :name => 'index_proposals_on_long_id'
  end
end
