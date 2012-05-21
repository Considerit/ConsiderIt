class Reflect::ReflectResponse < ActiveRecord::Base
  belongs_to :bullet, :class_name => 'Reflect::ReflectBullet', :foreign_key => 'bullet_id'
  has_many :revisions, :class_name => 'Reflect::ReflectResponseRevision', :foreign_key => 'response_id', :dependent => :destroy
  acts_as_tenant(:account)
end
