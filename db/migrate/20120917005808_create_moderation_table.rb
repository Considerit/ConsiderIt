class CreateModerationTable < ActiveRecord::Migration
  def self.up

    create_table :moderations do |t|

      t.references :user
      t.references :moderatable, :polymorphic => true
      t.integer :status

      t.timestamps
    end
                    
  end

  def self.down
    drop_table :moderations
  end
end
