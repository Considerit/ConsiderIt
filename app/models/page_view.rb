class PageView < ActiveRecord::Base
  acts_as_tenant :account
  belongs_to :user
end