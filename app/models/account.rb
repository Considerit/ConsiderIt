class Account < ActiveRecord::Base
  has_many :proposals, :dependent => :destroy
  has_many :points, :dependent => :destroy
  has_many :positions, :dependent => :destroy
  has_many :users, :dependent => :destroy
  has_many :comments, :dependent => :destroy, :class_name => 'Commentable::Comment'

  #TODO: replace with activity gem 
  has_many :activities, :class_name => 'Activity', :dependent => :destroy

  #has_many :reflect_bullets, :class_name => 'Reflect::ReflectBullet'
  #has_many :reflect_responses, :class_name => 'Reflect::ReflectResponse'

  #has_one :theme#, :polymorphic => true

  belongs_to :managing_account, :class_name => 'User'

  is_followable

  before_create :set_default

  def host_without_subdomain
    host_with_port.split('.')[-2, 2].join('.')
  end


  def self.all_themes
    Dir['app/assets/themes/*/'].map { |a| File.basename(a) }
  end

  def set_default
    header_text ||= 'The main callout to participants'
    header_details_text ||= 'This is where you\'ll add more details about why this forum exists, and whom you want to participate.'
  end
end
