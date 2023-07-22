class AddHideNameToProposals < ActiveRecord::Migration[6.1]
  def change
    add_column :proposals, :hide_name, :boolean, default: false
  end
end
