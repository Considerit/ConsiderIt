class AddStatementPreferencesToPosition < ActiveRecord::Migration
  def self.up
    add_column :positions, :notification_statement_subscriber, :boolean
    add_column :position_versions, :notification_statement_subscriber, :boolean    
  end

  def self.down
    add_column :positions, :notification_statement_subscriber, :boolean
    add_column :position_versions, :notification_statement_subscriber, :boolean    
  end
end
