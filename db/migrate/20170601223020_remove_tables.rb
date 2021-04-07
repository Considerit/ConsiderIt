class RemoveTables < ActiveRecord::Migration[5.2]
  def change
    begin 
      drop_table :emails
    rescue 
    end     
    drop_table :client_errors
  end
end
