class CleanupUsers < ActiveRecord::Migration
  def change
    begin
      remove_column :users, :notification_reflector
    rescue
      pp 'could not remove 1'
    end

    begin
      remove_column :users, :notification_responder
    rescue
      pp 'could not remove 2'
    end

    begin
      remove_column :users, :admin
    rescue
      pp 'could not remove 3'
    end
  end
end
