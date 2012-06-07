class AddHostToAccount < ActiveRecord::Migration
  def change
    add_column :accounts, :host, :string
    add_column :accounts, :host_with_port, :string
  end
end
