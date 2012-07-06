class AddIndexToPointLinks < ActiveRecord::Migration
  def change
    add_index :point_links, [:account_id, :point_id], :name => 'select_links_for_this_point'    
  end
end
