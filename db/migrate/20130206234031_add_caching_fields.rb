class AddCachingFields < ActiveRecord::Migration
  def change
    add_column :positions, :point_inclusions, :text
    add_column :proposals, :top_con, :integer
    add_column :proposals, :top_pro, :integer
    add_column :proposals, :participants, :text
  end
end
