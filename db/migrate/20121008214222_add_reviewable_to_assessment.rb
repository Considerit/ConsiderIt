class AddReviewableToAssessment < ActiveRecord::Migration
  def change
    add_column :assessments, :reviewable, :boolean, :default => false
  end
end
