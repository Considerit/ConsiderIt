class CreateThanksTable < ActiveRecord::Migration
  def self.up
    create_table :thanks do |t|
      t.references :user
      t.references :account
      t.references :thankable, :polymorphic => true
      t.timestamps
    end
                    
  end

  def self.down
    drop_table :thanks
  end
end
