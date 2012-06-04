class Reflect::ReflectBulletRevision < ActiveRecord::Base
  belongs_to :comment
  belongs_to :user
  is_trackable
  belongs_to :bullet, :class_name => 'Reflect::ReflectBullet', :foreign_key => 'bullet_id' 
  has_many :highlights, :class_name => 'Reflect::ReflectHighlight', :foreign_key => 'bullet_rev', :dependent => :destroy
  has_many :responses, :class_name => 'Reflect::ReflectResponseRevision', :foreign_key => 'bullet_rev', :dependent => :destroy

  acts_as_tenant(:account)

  default_scope where( :active => true )


end
