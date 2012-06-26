class Comment < ActiveRecord::Base
  is_reflectable
  is_trackable
  has_paper_trail  
  acts_as_followable
  
  #acts_as_nested_set :scope => [:commentable_id, :commentable_type]
  validates_presence_of :body
  validates_presence_of :user
    
  belongs_to :user
  belongs_to :commentable, :polymorphic=>true, :touch => true

  has_many :reflect_bullets, :class_name => 'Reflect::ReflectBullet', :dependent => :destroy
  has_many :reflect_bullet_revisions, :class_name => 'Reflect::ReflectBulletRevision', :dependent => :destroy

  acts_as_tenant(:account)

  # Helper class method that allows you to build a comment
  # by passing a commentable object, a user_id, and comment text
  # example in readme
  def self.build_from(obj, user_id, comment)
    c = self.new
    c.commentable_id = obj.id 
    c.commentable_type = obj.class.name 
    c.body = comment 
    c.user_id = user_id
    c
  end

  def violation
    false
  end

  def root_object
    commentable_type.constantize.find(commentable_id)
  end

end
