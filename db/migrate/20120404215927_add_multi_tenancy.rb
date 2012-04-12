class AddMultiTenancy < ActiveRecord::Migration
  def change
    create_table(:accounts) do |t|
      t.string :identifier
      t.string :theme

      t.timestamps
    end

    add_index :accounts, :identifier

    add_column :proposals, :account_id, :integer
    add_column :positions, :account_id, :integer
    add_column :points, :account_id, :integer
  end
end