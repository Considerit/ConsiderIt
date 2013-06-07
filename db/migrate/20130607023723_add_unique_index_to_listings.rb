class AddUniqueIndexToListings < ActiveRecord::Migration
  def change
    remove_column :point_listings, :inclusion_id
    remove_column :point_listings, :context
    remove_column :point_listings, :session_id   
  end
end
