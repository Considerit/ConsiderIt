class AddDivisivenessToPoint < ActiveRecord::Migration
  def change
    add_column :points, :divisiveness, :float
  end
end
