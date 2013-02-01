class CreateVerticals < ActiveRecord::Migration
  def up
    create_table :theme_directreps do |t|
      t.references :account

      t.string   :rep_name
      t.string  :rep_about
      t.string :website
      t.integer  :user_id
      t.timestamps
    end
    add_index :theme_directreps, :account_id
  end

  def down
    remove_index :theme_directreps, :account_id
    drop_table :theme_directreps
  end
end
