class AddModerationSettingsToAccount < ActiveRecord::Migration
  def change

    add_column :accounts, :moderate_points_mode, :integer, :default => 0
    add_column :accounts, :moderate_comments_mode, :integer, :default => 0
    add_column :accounts, :moderate_proposals_mode, :integer, :default => 0

  end
end
