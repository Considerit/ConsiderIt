class Ahoy::Event < ApplicationRecord
  acts_as_tenant :subdomain

  include Ahoy::QueryMethods

  self.table_name = "ahoy_events"

  belongs_to :visit
  belongs_to :user, optional: true
end
