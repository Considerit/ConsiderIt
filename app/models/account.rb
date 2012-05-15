class Account < ActiveRecord::Base
  has_many :proposals, :dependent => :destroy
  has_many :points, :dependent => :destroy
  has_many :positions, :dependent => :destroy

end
