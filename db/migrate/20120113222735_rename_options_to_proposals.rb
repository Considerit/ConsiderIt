class RenameOptionsToProposals < ActiveRecord::Migration
  def change
  	rename_table :options, :proposals

  	rename_column :inclusions, :option_id, :proposal_id
  	rename_column :points, :option_id, :proposal_id
  	rename_column :point_links, :option_id, :proposal_id
  	rename_column :point_listings, :option_id, :proposal_id
  	rename_column :point_similarities, :option_id, :proposal_id
  	rename_column :positions, :option_id, :proposal_id
  	rename_column :study_data, :option_id, :proposal_id
  	rename_column :domain_maps, :option_id, :proposal_id

    rename_column :positions, :notification_option_subscriber, :notification_proposal_subscriber

    remove_column :comments, :option_id
  end

end
