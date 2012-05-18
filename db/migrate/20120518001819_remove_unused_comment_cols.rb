class RemoveUnusedCommentCols < ActiveRecord::Migration
  def change
    remove_column :comments, :point_id
    remove_column :comments, :option_id
  end
end
