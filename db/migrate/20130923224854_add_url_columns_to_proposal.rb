class AddUrlColumnsToProposal < ActiveRecord::Migration
  def change
    rename_column :proposals, :url, :url1
    add_column :proposals, :url2, :string 
    add_column :proposals, :url3, :string
    add_column :proposals, :additional_description3, :text
  end
end
