class AddFollowUpToProposals < ActiveRecord::Migration[6.1]
  def change
    add_column :proposals, :follow_up, :string, limit: 10
  end
end
