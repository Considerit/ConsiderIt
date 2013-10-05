class AddSitemapEnabledToAccount < ActiveRecord::Migration
  def change
    add_column :accounts, :sitemap_enabled, :boolean, :default => false
  end
end
