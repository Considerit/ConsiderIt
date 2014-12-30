class AddRolesToProposal < ActiveRecord::Migration
  def change
    add_column :proposals, :roles, :text
  end
end
