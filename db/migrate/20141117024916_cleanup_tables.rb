class CleanupTables < ActiveRecord::Migration
  def change
    drop_table :rails_admin_histories
    drop_table :versions
    drop_table :activities
    drop_table :page_views
    drop_table :point_listings
    drop_table :sessions
    drop_table :thanks
  end
end
