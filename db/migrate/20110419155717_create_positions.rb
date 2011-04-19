class CreatePositions < ActiveRecord::Migration
  def self.up
    create_table :positions do |t|
      t.integer :option_id
      t.integer :user_id
      t.integer :session_id
      t.text :explanation
      t.float :stance
      t.integer :stance_bucket

      t.timestamps
    end
  end

  def self.down
    drop_table :positions
  end
end
