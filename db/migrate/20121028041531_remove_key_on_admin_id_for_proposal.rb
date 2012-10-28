class RemoveKeyOnAdminIdForProposal < ActiveRecord::Migration
  def change
    remove_index :proposals, :admin_id
  end
end
