class DomainMap < ActiveRecord::Base
  belongs_to :proposal
  belongs_to :domain

  acts_as_tenant(:account)  
end
