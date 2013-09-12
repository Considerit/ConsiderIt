class RenameVerdictColumns < ActiveRecord::Migration
  def change
    rename_column :claims, :verdict, :verdict_id
    rename_column :assessments, :overall_verdict, :verdict_id
  end

end
