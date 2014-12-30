class AddVerifiedToUser < ActiveRecord::Migration
  def change
    add_column :users, :verified, :boolean, :default => false
  end
end
