class CreateActivitiesTable < ActiveRecord::Migration
  def up
    create_table :activities do |t|
      t.string   :action_type, :null => false
      t.integer  :action_id,   :null => false
      t.integer  :account_id, :null => false
      t.integer  :user_id
      t.timestamps
    end
    add_index :activities, :account_id
  end

  def down
    remove_index :activities, :account_id
    drop_table :activities
  end
end
