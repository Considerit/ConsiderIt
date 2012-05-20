class Reflect::ReflectBullet < ActiveRecord::Base
  has_paper_trail

  belongs_to :comment

  has_many :revisions, :class_name => 'ReflectBulletRevision', :foreign_key => 'bullet_id', :dependent => :destroy  
  has_many :responses, :class_name => 'ReflectResponseRevision', :foreign_key => 'bullet_id', :dependent => :destroy
  has_many :highlights, :class_name => 'ReflectHighlight', :foreign_key => 'bullet_id', :dependent => :destroy
  
  acts_as_tenant(:account)
  
  def response
    if responses.count > 0
      responses[0]
    else
      nil
    end
  end
end
