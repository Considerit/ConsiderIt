class ConvertToJsonCols < ActiveRecord::Migration[5.2]
  def change
    change_column :proposals,   :histocache,    :json    
    change_column :proposals,   :json,    :json    
    change_column :proposals,   :roles,    :json    

    change_column :subdomains,  :roles,         :json
    change_column :subdomains,  :customizations,:json

    change_column :users,  :subscriptions, :json
    change_column :users,  :tags, :json
    change_column :users,  :active_in, :json
    change_column :users,  :emails, :json

    change_column :opinions,  :point_inclusions, :json

    change_column :points,  :includers, :json

    change_column :datastore,  :v, :json

  end
end
