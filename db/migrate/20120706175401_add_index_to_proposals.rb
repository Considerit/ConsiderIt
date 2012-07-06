class AddIndexToProposals < ActiveRecord::Migration
  def change
    add_index :proposals, [:account_id, :long_id], :name => 'select_proposal_by_long_id'
  end
end
