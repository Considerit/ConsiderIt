class AddColumnsForFollowable < ActiveRecord::Migration
  
  def up
    tables = [:accounts, :positions, :proposals, :points]
    tables.each do |tbl|
      add_column tbl, :followable_last_notification_milestone, :integer, :default => 0
      add_column tbl, :followable_last_notification, :datetime
    end
  end

  def down
    tables = [:accounts, :positions, :proposals, :points]
    tables.each do |tbl|
      remove_column tbl, :followable_last_notification_milestone
      remove_column tbl, :followable_last_notification
    end
  end    
end
