class ConvertUnpublishedOpinion < ActiveRecord::Migration
  def change
    rename_column :proposals, :num_unpublished_positions, :num_unpublished_opinions 
  end
end
