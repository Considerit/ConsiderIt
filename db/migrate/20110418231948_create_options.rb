class CreateOptions < ActiveRecord::Migration
  def self.up
    create_table :options do |t|
      t.string :designator
      t.string :category
      t.string :name
      t.string :short_name
      t.text :description
      t.string :image
      t.string :url

      t.timestamps
    end
  end

  def self.down
    drop_table :options
  end
end
