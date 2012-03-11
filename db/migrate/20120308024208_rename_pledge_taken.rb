class RenamePledgeTaken < ActiveRecord::Migration
  def change
    rename_column :users, :pledge_taken, :registration_complete
  end
end
