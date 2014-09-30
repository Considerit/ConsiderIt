class Comment < ActiveRecord::Base
  #is_reflectable
  include Moderatable #, Followable

  class_attribute :my_public_fields
  self.my_public_fields = [:id, :body, :user_id, :created_at, :point_id, :moderation_status ]

  scope :public_fields, -> {select(self.my_public_fields)}

  
  # has_paper_trail :only => [:title, :body, :subject, :user_id]  
  
  validates_presence_of :body
  validates_presence_of :user
    
  belongs_to :user
  belongs_to :point

  acts_as_tenant :account

  before_save do 
    self.body = self.body.sanitize
  end

  self.moderatable_fields = [:body]
  self.moderatable_objects = lambda {
    Comment.where('id > -1') #tacked on this where in order to enable chaining
  }

  # Helper class method that allows you to build a comment
  # by passing a commentable object, a user_id, and comment text
  # example in readme
  def self.build_from(obj, user_id, comment)
    c = self.new
    c.commentable_id = obj.id 
    c.commentable_type = obj.class.name 
    c.point_id = obj.id
    c.body = comment 
    c.user_id = user_id
    c
  end

  def as_json(options={})
    options[:only] ||= Comment.my_public_fields
    result = super(options)
    make_key(result, 'comment')
    stubify_field(result, 'user')
    stubify_field(result, 'point')
    result
  end

  def text(max_len = 140)
    body.length > max_len ? "#{body[(0..max_len)]}..." : body
  end

end
