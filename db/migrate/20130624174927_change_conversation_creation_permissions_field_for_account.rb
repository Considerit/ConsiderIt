class ChangeConversationCreationPermissionsFieldForAccount < ActiveRecord::Migration
  def change
    remove_column :accounts, :app_proposal_creation_permission
    add_column :accounts, :enable_user_conversations, :boolean, :default => false
  end
end
