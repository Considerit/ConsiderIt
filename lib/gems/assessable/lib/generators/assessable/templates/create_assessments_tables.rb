class CreateAssessableTables < ActiveRecord::Migration
  def self.up

    create_table :assessments do |t|

      t.references :user
      t.references :account
      t.references :assessable, :polymorphic => true
      t.integer :status

      t.timestamps
    end

    create_table :claims do |t|

      t.references :user
      t.references :assessments
      t.references :account
      t.references :assessable, :polymorphic => true
      t.integer :status

      t.timestamps
    end

  end

  def self.down
    drop_table :assessments
    drop_table :claims
  end
end
