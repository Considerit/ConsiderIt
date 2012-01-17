class DomainMap < ActiveRecord::Base
  belongs_to :proposal
  belongs_to :domain
end
