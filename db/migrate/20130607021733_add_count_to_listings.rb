class AddCountToListings < ActiveRecord::Migration
  def change


    ActiveRecord::Base.connection.execute "UPDATE positions SET account_id=(SELECT account_id FROM proposals WHERE positions.proposal_id=proposals.id)"
    ActiveRecord::Base.connection.execute "UPDATE points SET account_id=(SELECT account_id FROM proposals WHERE points.proposal_id=proposals.id)"
    ActiveRecord::Base.connection.execute "DELETE FROM point_listings WHERE point_id IS NULL"
    ActiveRecord::Base.connection.execute "DELETE FROM inclusions WHERE position_id NOT IN (SELECT id FROM positions)"
    
    add_column :point_listings, :count, :integer, :default => 1
    
    PointListing.warehouse()

  end
end
