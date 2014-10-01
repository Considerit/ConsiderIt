class AddPointToComment < ActiveRecord::Migration
  def change
    add_column :comments, :point_id, :integer
  end
end
