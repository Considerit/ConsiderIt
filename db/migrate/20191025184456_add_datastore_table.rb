class AddDatastoreTable < ActiveRecord::Migration
  def change

    create_table :datastore, id: false do |t|
      t.string "k", null: false
      t.text   "v", :limit => 4294967  
    end

    add_index :datastore, :k, unique: true
  end

end
