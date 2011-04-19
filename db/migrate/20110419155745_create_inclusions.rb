class CreateInclusions < ActiveRecord::Migration
  def self.up
    create_table :inclusions do |t|
      t.integer :option_id
      t.integer :position_id
      t.integer :point_id
      t.integer :user_id
      t.integer :session_id
      t.boolean :included_as_pro

      t.timestamps
    end
  end

  def self.down
    drop_table :inclusions
  end
end
