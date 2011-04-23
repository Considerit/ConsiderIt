class CreatePositions < ActiveRecord::Migration
  def self.up
    create_table :positions do |t|
      t.references :option
      t.references :user
      t.integer :session_id
      t.text :explanation
      t.float :stance
      t.integer :stance_bucket
      
      t.boolean :published, :default => false

      t.timestamps
    end
  end

  def self.down
    drop_table :positions
  end
end
