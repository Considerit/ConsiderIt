class FixColumnError < ActiveRecord::Migration
  def change
    rename_column :subdomains, :external_external_project_url, :external_project_url
  end
end
