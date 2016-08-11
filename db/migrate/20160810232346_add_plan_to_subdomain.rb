class AddPlanToSubdomain < ActiveRecord::Migration
  def change
    add_column :subdomains, :plan, :integer, default: 0
  end
end
