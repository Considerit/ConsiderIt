class CreateInclusions < ActiveRecord::Migration
  def self.up
    create_table :inclusions do |t|
      t.references :option
      t.references :position
      t.references :point
      t.references :user
      t.integer :session_id
      t.boolean :included_as_pro

      t.timestamps
    end
  end

  def self.down
    drop_table :inclusions
  end
end
