class AddHideNameToComments < ActiveRecord::Migration[6.1]
  def change
    add_column :comments, :hide_name, :boolean, default: false
  end
end
