class AddNotesToAssessment < ActiveRecord::Migration
  def change
    add_column :assessments, :notes, :text
  end
end
