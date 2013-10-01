class AddUrl4ToProposal < ActiveRecord::Migration
  def change
    add_column :proposals, :url4, :string
  end
end
