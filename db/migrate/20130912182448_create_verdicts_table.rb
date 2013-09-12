class CreateVerdictsTable < ActiveRecord::Migration
  def up
     create_table :verdicts do |t|
       t.string :short_name
       t.string :name
       t.text :desc
       t.timestamps
    end
    add_attachment :verdicts, :icon
  end

  def down
    drop_table :verdicts
  end
end
