class AddPaymentsFields < ActiveRecord::Migration[5.2]
  def change
    add_column :subdomains, :created_by, :integer
    add_foreign_key :subdomains, :users, column: :created_by

    add_column :users, :paid_forums, :integer, default: 0

  end
end
