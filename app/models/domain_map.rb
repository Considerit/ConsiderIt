class DomainMap < ActiveRecord::Base
  belongs_to :option
  belongs_to :domain
end
