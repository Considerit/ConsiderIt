class AddUnconfirmedEmailToDevise < ActiveRecord::Migration
  def change
    begin
      add_column :users, :unconfirmed_email, :string
    rescue
    end
  end
end
