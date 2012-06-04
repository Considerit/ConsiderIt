class Reflect::ReflectResponseRevision < ActiveRecord::Base
  belongs_to :bullet, :class_name => 'Reflect::ReflectBullet', :foreign_key => 'bullet_id'
  belongs_to :bullet_revision, :class_name => 'Reflect::ReflectBulletRevision', :foreign_key => 'bullet_rev'
  belongs_to :user
  
  belongs_to :response, :class_name => 'Reflect::ReflectResponse', :foreign_key => 'response_id'
  acts_as_tenant(:account)
  
  default_scope where( :active => true )
    
end