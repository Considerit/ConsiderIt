class CreateAssessmentsTables < ActiveRecord::Migration
  def self.up

    create_table :assessments do |t|

      t.references :user
      t.references :account
      t.references :assessable, :polymorphic => true

      t.boolean :qualifies
      t.string :qualifies_reason
      t.integer :overall_verdict

      t.boolean :complete, :default => false

      t.timestamps
    end

    create_table :claims do |t|

      t.references :assessment, :class_name => 'Assessable::Assessment'
      t.references :account
      t.string :assessment
      t.string :claim
      t.integer :verdict

      t.timestamps
    end


    create_table :requests do |t|

      t.references :user
      t.references :assessment, :class_name => 'Assessable::Assessment'      
      t.references :account

      t.string :suggestion
      t.timestamps
    end

  end

  def self.down
    drop_table :assessments
    drop_table :claims
    drop_table :requests
  end
end
