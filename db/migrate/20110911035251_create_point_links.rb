class CreatePointLinks < ActiveRecord::Migration
  def self.up
    create_table :point_links do |t|
      t.belongs_to :point
      t.references :option
      t.references :user

      t.string :url
      t.string :description

      t.boolean :approved, :default => true

      t.timestamps
    end
  end

  def self.down
    drop_table :point_links
  end
end