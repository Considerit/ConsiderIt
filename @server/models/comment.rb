class Comment < ApplicationRecord
  include Moderatable, Notifier

  class_attribute :my_public_fields
  self.my_public_fields = [:id, :body, :user_id, :hide_name, :created_at, :point_id, :moderation_status, :subdomain_id ]

  scope :public_fields, -> {select(self.my_public_fields)}
  
  validates_presence_of :body
  validates_presence_of :user
    
  belongs_to :user
  belongs_to :point

  has_one :proposal, :through => :point

  acts_as_tenant :subdomain


  before_save do 
    self.body = sanitize_helper(self.body) if self.body
  end


  def as_json(options={})
    options[:only] ||= Comment.my_public_fields
    result = super(options)
    make_key(result, 'comment')
    stubify_field(result, 'user')
    stubify_field(result, 'point')


    # If anonymous, hide user id
    if (result['hide_name'] && (current_user.nil? || current_user.id != result['user_id']))
      result['user_id'] = -1
    end

    result
  end

  def proposal
    point.proposal
  end

  # Fetches all comments associated with this Point. 
  def self.comments_for_point(point)
    if current_subdomain.moderation_policy == 1
      moderation_status_check = 'moderation_status=1'
    else 
      moderation_status_check = '(moderation_status IS NULL OR moderation_status=1)'
    end
    
    comments = {
      :comments => point.comments.where("#{moderation_status_check} OR user_id=#{current_user.id}"),
      :key => "/comments/#{point.id}"
    }


    comments

  end


  # Fetches all comments associated with this Forum.
  def self.comments_for_forum(forum=nil)
    forum ||= current_subdomain
    if forum.moderation_policy == 1
      moderation_status_check = 'moderation_status=1'
    else 
      moderation_status_check = '(moderation_status IS NULL OR moderation_status=1)'
    end
    
    comments = {
      :comments => forum.comments.where("#{moderation_status_check} OR user_id=#{current_user.id}"),
      :key => "/all_comments"
    }


    comments

  end


end
