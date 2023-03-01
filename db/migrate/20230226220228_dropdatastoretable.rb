class Dropdatastoretable < ActiveRecord::Migration[6.1]
  def change
    drop_table :datastore
  end
end
