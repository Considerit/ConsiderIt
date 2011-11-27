class Reflect::ReflectBullet < ActiveRecord::Base
  belongs_to :comment

  has_many :revisions, :class_name => 'ReflectBulletRevision', :foreign_key => 'bullet_id'  
  has_many :responses, :class_name => 'ReflectResponseRevision', :foreign_key => 'bullet_id'
  has_many :highlights, :class_name => 'ReflectHighlight', :foreign_key => 'bullet_id'
  
  def response
    if responses.count > 0
      responses[0]
    else
      nil
    end
  end
end
