class AddAccountToModeration < ActiveRecord::Migration
  def change
    add_column :moderations, :account_id, :integer
  end
end
