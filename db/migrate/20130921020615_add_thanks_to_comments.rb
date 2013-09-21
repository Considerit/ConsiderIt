class AddThanksToComments < ActiveRecord::Migration
  def change
    add_column :comments, :thanks_count, :integer, :default => 0
  end
end
