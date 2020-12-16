class IncreaseProposalDescriptionSize < ActiveRecord::Migration
  def change
    change_column :proposals, :description, :text, :limit => 16.megabytes - 1
  end
end
