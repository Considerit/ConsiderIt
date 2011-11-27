class Reflect::ReflectHighlight < ActiveRecord::Base
  belongs_to :bullet_revision, :class_name => 'ReflectBulletRevision', :foreign_key => 'bullet_rev'
  belongs_to :bullet, :class_name => 'ReflectBullet', :foreign_key => 'bullet_id'
end
