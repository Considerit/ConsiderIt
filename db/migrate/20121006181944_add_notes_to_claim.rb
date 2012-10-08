class AddNotesToClaim < ActiveRecord::Migration
  def change
    add_column :claims, :notes, :string
    rename_column :claims, :assessment, :result
  end
end
