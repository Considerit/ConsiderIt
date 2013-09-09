class AddModerationSettingsToForModels < ActiveRecord::Migration
  def change
    remove_column :points, :passes_moderation
    remove_column :comments, :passes_moderation
  end
end
