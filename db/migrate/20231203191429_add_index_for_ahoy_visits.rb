class AddIndexForAhoyVisits < ActiveRecord::Migration[6.1]
  def change
    add_index :ahoy_visits, [:visitor_token, :started_at]
  end
end
