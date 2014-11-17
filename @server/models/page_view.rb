class PageView < ActiveRecord::Base
  acts_as_tenant :subdomain
  belongs_to :user
end