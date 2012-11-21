class AddPublicityToProposals < ActiveRecord::Migration
  def change
    add_column :proposals, :publicity, :integer, :default => 2
    add_column :proposals, :access_list, :binary, :limit => 1.megabyte, :default => ''
  end
end
