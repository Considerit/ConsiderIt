class CreateClientErrors < ActiveRecord::Migration
  def change
    create_table :client_errors do |t|
      t.text :trace
      t.string :error_type
      t.string :line
      t.string :message
      t.integer :user_id, :default => nil
      t.string :session_id
      t.string :user_agent
      t.string :browser
      t.string :version
      t.string :platform
      t.string :location
      t.string :ip

      t.timestamps
    end
  end
end
