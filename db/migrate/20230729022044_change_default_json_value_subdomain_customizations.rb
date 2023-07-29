class ChangeDefaultJsonValueSubdomainCustomizations < ActiveRecord::Migration[6.1]
  def change
    Subdomain.where(customizations: nil).update_all(customizations: {}.to_json)
  end
end
