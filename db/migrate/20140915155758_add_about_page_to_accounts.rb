class AddAboutPageToAccounts < ActiveRecord::Migration
  def change
    add_column :accounts, :about_page_url, :string
  end
end
