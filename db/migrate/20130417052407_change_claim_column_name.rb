class ChangeClaimColumnName < ActiveRecord::Migration
  def change
    rename_column :claims, :claim, :claim_restatement
  end
end
