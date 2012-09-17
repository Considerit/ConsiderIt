class AddModerationFieldsToModeratables < ActiveRecord::Migration
  def change
    add_column :comments, :moderation_status, :integer
    add_column :points, :moderation_status, :integer
    add_column :proposals, :moderation_status, :integer

    add_index :points, [:account_id, :proposal_id, :published, :moderation_status, :is_pro], :name => 'select_acceptable_pros_or_cons'
    add_index :comments, [:account_id, :commentable_id, :commentable_type, :moderation_status], :name => 'select_comments'

  end
end
