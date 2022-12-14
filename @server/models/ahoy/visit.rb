class Ahoy::Visit < ApplicationRecord
  acts_as_tenant :subdomain  
  
  self.table_name = "ahoy_visits"

  has_many :events, class_name: "Ahoy::Event"
  belongs_to :user, optional: true
end
