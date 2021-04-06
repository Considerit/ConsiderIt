class AddPlanToSubdomain < ActiveRecord::Migration[5.2]
  def change
    add_column :subdomains, :plan, :integer, default: 0
  end
end
