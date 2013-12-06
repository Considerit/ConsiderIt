class AddProjectUrlToAccount < ActiveRecord::Migration
  def change
    add_column :accounts, :project_url, :string
  end
end
