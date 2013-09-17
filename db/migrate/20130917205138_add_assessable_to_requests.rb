class AddAssessableToRequests < ActiveRecord::Migration
  def change
    add_column :requests, :assessable_id, :integer
    add_column :requests, :assessable_type, :string
  end
end
