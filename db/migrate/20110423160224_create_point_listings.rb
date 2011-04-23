class CreatePointListings < ActiveRecord::Migration
  def self.up
    create_table :point_listings do |t|
      t.references :option
      t.references :position
      t.references :point
      t.references :user
      t.references :inclusion
      t.integer :session_id
      t.integer :context

      t.timestamps
    end
  end

  def self.down
    drop_table :point_listings
  end
end
