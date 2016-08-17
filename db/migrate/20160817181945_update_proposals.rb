class UpdateProposals < ActiveRecord::Migration
  def change
    change_column :proposals, :name, :text
    remove_column :proposals, :category
    remove_column :proposals, :designator
    drop_table :follows
  end
end
