class ConvertPositionToOpinion < ActiveRecord::Migration
  def change
    rename_table :positions, :opinions
    rename_column :inclusions, :position_id, :opinion_id
    rename_column :point_listings, :position_id, :opinion_id
    rename_column :points, :position_id, :opinion_id
    rename_column :users, :metric_positions, :metric_opinions
  end

end
