class AddDefaultOptionsToAccount < ActiveRecord::Migration
  def change
    add_column :accounts, :pro_label, :string
    add_column :accounts, :con_label, :string
    add_column :accounts, :slider_right, :string
    add_column :accounts, :slider_left, :string    
    add_column :accounts, :slider_prompt, :string
    add_column :accounts, :considerations_prompt, :string
    add_column :accounts, :statement_prompt, :string
    add_column :accounts, :entity, :string
    add_column :accounts, :enable_position_statement, :boolean
  end

end
