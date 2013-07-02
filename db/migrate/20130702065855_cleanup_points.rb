class CleanupPoints < ActiveRecord::Migration
  def change

   [:points, :inclusions, :positions].each do |tbl|
      begin
        remove_column tbl, :version
      rescue
      end
      begin
        remove_column tbl, :deleted_at
      rescue
      end      
    end

    [:notification_demonstrated_interest, :notification_point_subscriber, :notification_perspective_subscriber, :notification_author, :notification_statement_subscriber].each do |col|
      begin
        remove_column :positions, col
      rescue
      end
    end
  end
end
