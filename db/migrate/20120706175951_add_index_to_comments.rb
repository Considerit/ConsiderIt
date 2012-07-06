class AddIndexToComments < ActiveRecord::Migration
  def change
    add_index :comments, [:account_id, :commentable_id, :commentable_type], :name => 'select_comments_on_commentable'
  end
end
