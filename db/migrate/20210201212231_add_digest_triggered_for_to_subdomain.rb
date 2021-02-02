class AddDigestTriggeredForToSubdomain < ActiveRecord::Migration[5.2]
  def change
    add_column :subdomains, :digest_triggered_for, :json
  end
end
