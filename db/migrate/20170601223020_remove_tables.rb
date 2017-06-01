class RemoveTables < ActiveRecord::Migration
  def change
    begin 
      drop_table :emails
    rescue 
    end     
    drop_table :client_errors
  end
end
