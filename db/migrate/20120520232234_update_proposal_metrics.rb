class UpdateProposalMetrics < ActiveRecord::Migration
  def change
    rename_column :proposals, :persuasiveness, :provocative
    rename_column :proposals, :score, :trending
    rename_column :proposals, :devisiveness, :contested

    add_column :proposals, :num_unpublished_positions, :integer
  end

end
