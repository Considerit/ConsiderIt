class Account < ActiveRecord::Base
  has_many :proposals, :dependent => :destroy
  has_many :points, :dependent => :destroy
  has_many :positions, :dependent => :destroy
  has_many :domains, :dependent => :destroy
  has_many :users, :dependent => :destroy
  has_many :comments, :dependent => :destroy

  #TODO: replace with activity gem 
  has_many :activities, :class_name => 'Activity', :dependent => :destroy

  acts_as_followable
end
