class Reflect::ReflectHighlight < ActiveRecord::Base
  belongs_to :bullet_revision, :class_name => 'Reflect::ReflectBulletRevision', :foreign_key => 'bullet_rev'
  belongs_to :bullet, :class_name => 'Reflect::ReflectBullet', :foreign_key => 'bullet_id'
  acts_as_tenant(:account)
end
