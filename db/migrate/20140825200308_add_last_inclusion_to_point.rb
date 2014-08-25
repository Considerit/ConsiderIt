class AddLastInclusionToPoint < ActiveRecord::Migration
  def change
    add_column :points, :last_inclusion, :integer, :default => 0
  end
end
