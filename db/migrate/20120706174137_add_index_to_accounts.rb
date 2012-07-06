class AddIndexToAccounts < ActiveRecord::Migration
  def change
    add_index :accounts, :identifier
  end
end
