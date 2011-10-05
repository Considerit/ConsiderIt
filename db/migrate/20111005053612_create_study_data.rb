class CreateStudyData < ActiveRecord::Migration
  def self.up
    create_table :study_data do |t|
      t.references :option
      t.references :user
      t.references :position
      t.references :point
      
      t.integer :category
      t.integer :session_id

      t.text :detail1
      t.text :detail2

      t.integer :ival
      t.float :fval      
      t.boolean :bval

      t.timestamps
    end
  end

  def self.down
    drop_table :study_data
  end
end
