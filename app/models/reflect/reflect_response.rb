class Reflect::ReflectResponse < ActiveRecord::Base
  belongs_to :bullet, :class_name => 'ReflectBullet', :foreign_key => 'bullet_id'
  has_many :revisions, :class_name => 'ReflectResponseRevision', :foreign_key => 'response_id', :dependent => :destroy
end
