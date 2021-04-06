class AddIndexesToUsers < ActiveRecord::Migration[5.2]
  def change
    add_index :users, :registered
  end
end
