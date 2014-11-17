class Comment < ActiveRecord::Base
  include Moderatable

  class_attribute :my_public_fields
  self.my_public_fields = [:id, :body, :user_id, :created_at, :point_id, :moderation_status ]

  scope :public_fields, -> {select(self.my_public_fields)}
  
  validates_presence_of :body
  validates_presence_of :user
    
  belongs_to :user
  belongs_to :point

  acts_as_tenant :subdomain

  before_save do 
    self.body = self.body.sanitize
  end

  self.moderatable_fields = [:body]
  self.moderatable_objects = lambda {
    Comment.where('id > -1') #tacked on this where in order to enable chaining
  }

  def as_json(options={})
    options[:only] ||= Comment.my_public_fields
    result = super(options)
    make_key(result, 'comment')
    stubify_field(result, 'user')
    stubify_field(result, 'point')
    result
  end


  # Fetches all comments associated with this Point. 
  # Because we generally render fact-checks in the comment stream, we also return
  # fact-checks for this point  
  def self.comments_for_point(point)
    current_tenant = Thread.current[:tenant]

    comments = {
      :comments => point.comments.where('moderation_status = 1 or moderation_status IS NULL'),
      :key => "/comments/#{point.id}"
    }

    if current_tenant.assessment_enabled
      comments.update({
        :assessment => point.assessment && point.assessment.complete ? point.assessment : nil,
        :verdicts => Assessable::Verdict.all,
        :claims => point.assessment && point.assessment.complete ? point.assessment.claims : nil,
        :requests => point.assessment ? point.assessment.requests : nil
      })
    end

    comments

  end

end
