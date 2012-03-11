class AddUnconfirmedEmailToDevise < ActiveRecord::Migration
  def change
    add_column :users, :unconfirmed_email, :string
  end
end
