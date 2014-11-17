class ContinueRenamingColumns < ActiveRecord::Migration
  def change
    rename_column :subdomains, :identifier, :name
  end
end
