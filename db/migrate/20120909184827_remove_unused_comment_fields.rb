class RemoveUnusedCommentFields < ActiveRecord::Migration
  def change
    remove_column :comments, :parent_id  
    remove_column :comments, :lft      
    remove_column :comments, :rgt
  end

end
