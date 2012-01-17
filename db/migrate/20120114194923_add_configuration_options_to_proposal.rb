class AddConfigurationOptionsToProposal < ActiveRecord::Migration
  def change
    add_column :proposals, :poles, :string
    add_column :proposals, :slider_prompt, :string
    add_column :proposals, :considerations_prompt, :string
    add_column :proposals, :statement_prompt, :string
    add_column :proposals, :headers, :string
    add_column :proposals, :entity, :string
    add_column :proposals, :discussion_mode, :string
    add_column :proposals, :enable_position_statement, :boolean
  end
end


