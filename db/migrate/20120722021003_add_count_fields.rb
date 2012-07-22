class AddCountFields < ActiveRecord::Migration
  def up
    add_column :points, :comment_count, :integer, :default => 0
    add_column :points, :point_link_count, :integer, :default => 0
  end

  def down
  end
end
