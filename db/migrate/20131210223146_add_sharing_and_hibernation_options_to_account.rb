class AddSharingAndHibernationOptionsToAccount < ActiveRecord::Migration
  def change
    add_column :accounts, :enable_hibernation, :boolean, :default => false
    add_column :accounts, :enable_sharing, :boolean, :default => false
    add_column :accounts, :hibernation_message, :string
  end
end
