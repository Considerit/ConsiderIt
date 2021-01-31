class AddModerationPolicyToSubdomain < ActiveRecord::Migration[5.2]
  def change
    add_column :subdomains, :moderation_policy, :integer, :default => 0
  end
end
