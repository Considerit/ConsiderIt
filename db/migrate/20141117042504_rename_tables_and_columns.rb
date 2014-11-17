class RenameTablesAndColumns < ActiveRecord::Migration
  def change
    rename_table :accounts, :subdomains
    rename_column :assessments, :account_id, :subdomain_id
    rename_column :claims, :account_id, :subdomain_id
    rename_column :comments, :account_id, :subdomain_id
    rename_column :follows, :account_id, :subdomain_id
    rename_column :inclusions, :account_id, :subdomain_id
    rename_column :logs, :account_id, :subdomain_id
    rename_column :moderations, :account_id, :subdomain_id
    rename_column :opinions, :account_id, :subdomain_id
    rename_column :points, :account_id, :subdomain_id
    rename_column :proposals, :account_id, :subdomain_id
    rename_column :requests, :account_id, :subdomain_id
    rename_column :verdicts, :account_id, :subdomain_id
    remove_column :users, :account_id


  end
end
