class AddHeaderFieldsToAccountFix < ActiveRecord::Migration
  def change
    rename_column :accounts, :managing_account, :managing_account_id

  end
end
