class AddSinglePageSwitchToTheme < ActiveRecord::Migration
  def change
    add_column :accounts, :single_page, :boolean, :default => false
  end
end
