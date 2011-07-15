class CreatePointSimilarities < ActiveRecord::Migration
  def self.up
    create_table :point_similarities do |t|
      t.belongs_to :p1
      t.belongs_to :p2
      t.references :option
      t.references :user
      t.integer :value

      t.timestamps
    end
  end

  def self.down
    drop_table :point_similarities
  end
end
