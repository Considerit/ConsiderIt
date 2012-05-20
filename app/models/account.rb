class Account < ActiveRecord::Base
  has_many :proposals, :dependent => :destroy
  has_many :points, :dependent => :destroy
  has_many :positions, :dependent => :destroy
  has_many :domains, :dependent => :destroy
  has_many :users, :dependent => :destroy
  has_many :comments, :dependent => :destroy
end
