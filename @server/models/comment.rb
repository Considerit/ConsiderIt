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
      :comments => point.comments,
      :key => "/comments/#{point.id}"
    }

    if current_tenant.assessment_enabled
      comments.update({
        :assessment => point.assessment && point.assessment.complete ? point.assessment.public_fields : nil,
        :verdicts => Assessable::Verdict.all,
        :claims => point.assessment && point.assessment.complete ? point.assessment.claims.public_fields : nil,
        :already_requested_assessment => current_user && Assessable::Request.where(:assessable_id => point.id, :assessable_type => 'Point', :user_id => current_user.id).count > 0
      })
    end

    comments

  end

end
