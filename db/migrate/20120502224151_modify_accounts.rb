class ModifyAccounts < ActiveRecord::Migration
  def change
    remove_column :accounts, :appearance_base_color
    remove_column :accounts, :appearance_style

    rename_column :accounts, :app_creation_permission, :app_proposal_creation_permission

    add_column :accounts, :app_require_registration_for_perspective, :boolean, :default => false


  end

end
