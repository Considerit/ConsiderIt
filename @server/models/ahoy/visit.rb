class Ahoy::Visit < ApplicationRecord
  acts_as_tenant :subdomain  
  
  self.table_name = "ahoy_visits"

  has_many :events, class_name: "Ahoy::Event"
  belongs_to :user, optional: true

  class_attribute :my_public_fields
  self.my_public_fields = [:browser, :ip, :device_type, :landing_page, :referrer, :referring_domain, :started_at, :user_id]

  def as_json(options={})
    options[:only] ||= Ahoy::Visit.my_public_fields
    result = super(options)
    stubify_field(result, 'user')
    result
  end



end
