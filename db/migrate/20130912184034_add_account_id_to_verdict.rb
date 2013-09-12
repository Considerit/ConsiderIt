class AddAccountIdToVerdict < ActiveRecord::Migration
  def change
    add_column :verdicts, :account_id, :integer
  end
end
