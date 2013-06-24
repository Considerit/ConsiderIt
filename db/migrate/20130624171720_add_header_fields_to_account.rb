class AddHeaderFieldsToAccount < ActiveRecord::Migration
  def change
    add_column :accounts, :managing_account, :integer
    add_column :accounts, :header_text, :text
    add_column :accounts, :header_details_text, :text
  end
end
