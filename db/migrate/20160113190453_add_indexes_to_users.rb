class AddIndexesToUsers < ActiveRecord::Migration
  def change
    add_index :users, :registered
  end
end
