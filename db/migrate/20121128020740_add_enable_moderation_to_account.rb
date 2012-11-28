class AddEnableModerationToAccount < ActiveRecord::Migration
  def change
    add_column :accounts, :enable_moderation, :boolean, :default => false
  end
end
