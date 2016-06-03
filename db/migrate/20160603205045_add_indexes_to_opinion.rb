class AddIndexesToOpinion < ActiveRecord::Migration
  def change
    add_index :opinions, [:subdomain_id, :proposal_id, :user_id]
    remove_column :opinions, :stance_segment
  end
end
