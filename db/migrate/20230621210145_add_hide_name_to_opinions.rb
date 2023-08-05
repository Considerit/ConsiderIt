class AddHideNameToOpinions < ActiveRecord::Migration[6.1]
  def change
    add_column :opinions, :hide_name, :boolean, default: false
  end
end
