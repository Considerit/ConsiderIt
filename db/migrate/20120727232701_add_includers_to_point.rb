class AddIncludersToPoint < ActiveRecord::Migration
  def change
    add_column :points, :includers, :text
  end
end


