class AddTagsToUsersAndProposals < ActiveRecord::Migration
  def change
    add_column :users, :tags, :text
    add_column :proposals, :tags, :text
  end
end
