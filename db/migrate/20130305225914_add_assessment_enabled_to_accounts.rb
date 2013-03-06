class AddAssessmentEnabledToAccounts < ActiveRecord::Migration
  def change
    add_column :accounts, :assessment_enabled, :boolean, :default => false
  end
end
