class CreateFollowTable < ActiveRecord::Migration
  def self.up

    create_table :follows do |t|

      t.references :user
      t.references :followable, :polymorphic => true

      t.boolean :follow, :default => true
      t.boolean :explicit, :default => false

      t.references :account
      t.timestamps
    end
                    
  end

  def self.down
    drop_table :follows
  end
end
