class CreatePageView < ActiveRecord::Migration
  def up
    create_table :page_views do |t|
      t.references :user
      t.references :account
      t.text :referer
      t.string :session
      t.string :user_agent
      t.string :ip_address
      t.datetime :created_at
    end    
  end

  def down
    drop_table :page_views
  end
end
