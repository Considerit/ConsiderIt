class AddGroupToProposal < ActiveRecord::Migration
  def change
    add_column :proposals, :cluster, :string
  end
end
