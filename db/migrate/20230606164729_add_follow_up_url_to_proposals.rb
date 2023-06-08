class AddFollowUpUrlToProposals < ActiveRecord::Migration[6.1]
  def change
    add_column :proposals, :follow_up_url, :text
  end
end
