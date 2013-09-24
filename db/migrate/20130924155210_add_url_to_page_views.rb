class AddUrlToPageViews < ActiveRecord::Migration
  def change
    add_column :page_views, :url, :string
  end
end
