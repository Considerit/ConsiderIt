class AddCacheToProposals < ActiveRecord::Migration
  def change
    add_column :proposals, :histocache, :text, :limit => 4294967
  end
end
