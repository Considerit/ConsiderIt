class AddIndexes2 < ActiveRecord::Migration
  def change
    add_index :positions, [:account_id, :proposal_id, :published], :name => 'select_published_positions'
    add_index :points, [:account_id, :proposal_id, :published, :is_pro], :name => 'select_published_pros_or_cons'
    add_index :users, [:account_id, :id], :name => 'select_user'
    add_index :proposals, [:account_id, :id], :name => 'select_proposal'
  end

end
