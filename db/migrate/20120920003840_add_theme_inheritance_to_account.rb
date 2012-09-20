class AddThemeInheritanceToAccount < ActiveRecord::Migration
  def change
    add_column :accounts, :inherited_themes, :string
  end
end
