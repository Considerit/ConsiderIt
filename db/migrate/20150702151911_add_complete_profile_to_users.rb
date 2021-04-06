class AddCompleteProfileToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :complete_profile, :boolean, default: false
  end
end
