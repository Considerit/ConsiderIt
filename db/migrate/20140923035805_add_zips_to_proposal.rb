class AddZipsToProposal < ActiveRecord::Migration
  def change
    add_column :proposals, :zips, :text
    rename_column :proposals, :targettable, :hide_on_homepage
  end
end
