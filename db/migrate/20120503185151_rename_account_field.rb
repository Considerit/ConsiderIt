class RenameAccountField < ActiveRecord::Migration
  def change
    rename_column :accounts, :socmedia_facebook_id, :socmedia_facebook_client
    add_column :accounts, :requires_civility_pledge_on_registration, :boolean, :default => false
  end
end
