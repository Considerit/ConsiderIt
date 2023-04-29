class Drophistocachefromproposals < ActiveRecord::Migration[6.1]
  def change
    remove_column :proposals, :histocache 
  end
end
