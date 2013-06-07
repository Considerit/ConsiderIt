class AddUniqueIndexToPointListingsForReal < ActiveRecord::Migration
  def change
    add_index :point_listings, [:user_id, :point_id], :unique => true
  end
end
