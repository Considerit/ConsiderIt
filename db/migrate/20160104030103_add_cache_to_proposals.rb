class AddCacheToProposals < ActiveRecord::Migration[5.2]
  def change
    add_column :proposals, :histocache, :text, :limit => 4294967
  end
end
