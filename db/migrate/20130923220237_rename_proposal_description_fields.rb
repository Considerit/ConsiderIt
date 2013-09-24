class RenameProposalDescriptionFields < ActiveRecord::Migration
  def change
    rename_column :proposals, :long_description, :additional_description1
    rename_column :proposals, :additional_details, :additional_description2
  end
end
