class AddIndexToAccounts < ActiveRecord::Migration
  def change
    add_index :accounts, :identifier, :name => 'by_identifier'
  end
end
