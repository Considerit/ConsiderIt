class RemoveMoreTables < ActiveRecord::Migration[5.2]
  def change
    drop_table :assessments
    drop_table :claims
    drop_table :verdicts
    drop_table :requests
  end
end
