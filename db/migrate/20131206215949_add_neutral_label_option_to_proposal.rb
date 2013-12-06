class AddNeutralLabelOptionToProposal < ActiveRecord::Migration
  def change
    add_column :proposals, :slider_middle, :string
  end
end
