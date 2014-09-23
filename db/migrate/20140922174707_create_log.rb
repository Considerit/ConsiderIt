class CreateLog < ActiveRecord::Migration
  def change
    create_table :logs do |t|
      t.integer :account_id
      t.integer :who # user_id
      t.string :what # the behavior
      t.string :where # the page on which it took place
      t.datetime :when # when it happened
      t.text :details # additional information
    end
  end
end
