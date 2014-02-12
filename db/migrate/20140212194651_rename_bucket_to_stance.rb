class RenameBucketToStance < ActiveRecord::Migration
  def change
    rename_column :opinions, :stance_bucket, :stance_segment
  end
end
