class AddTrustedToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :trusted, :boolean, :default => false
  end
end
