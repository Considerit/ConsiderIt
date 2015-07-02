class AddCompleteProfileToUsers < ActiveRecord::Migration
  def change
    add_column :users, :complete_profile, :boolean, default: false
  end
end
