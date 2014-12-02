# coding: utf-8
class Point < ActiveRecord::Base
  
  include Followable, Moderatable, Assessable
    
  belongs_to :user
  belongs_to :proposal
  has_many :inclusions, :dependent => :destroy
  has_many :comments, :dependent=>:destroy  
  
  validates :nutshell, :presence => true, :length => { :maximum => 141 }


  before_validation do 
    #self.nutshell = self.nutshell.sanitize
    #self.text = self.text.sanitize

    if self.nutshell.length > 140 
      self.text = self.text ? "#{self.nutshell[139..-1]} #{self.text}" : self.nutshell[139..-1]
      self.nutshell = self.nutshell[0..139]
    end

    if self.nutshell.length == 0 && !self.text.nil? && self.text.length > 0
      self.text =  self.text[139..self.text.length]
      self.nutshell = self.text[0..139]
    end

  end

  acts_as_tenant :subdomain

  self.moderatable_fields = [:nutshell, :text]
  self.moderatable_objects = lambda {
    Point.joins(:proposal).published.where(:proposals => {:active => true})
  }

  self.assessable_fields = [:nutshell, :text]
  self.assessable_objects = lambda {
    Point.joins(:proposal).published.where(:proposals => {:active => true})
  }

  class_attribute :my_public_fields
  self.my_public_fields = [:comment_count, :created_at, :id, :includers, :is_pro, :nutshell, :proposal_id, :published, :score, :text, :user_id, :hide_name, :last_inclusion]

  scope :public_fields, -> {select(self.my_public_fields)}

  scope :named, -> {where( :hide_name => false )}
  scope :published, -> {where( :published => true )}
  
  scope :pros, -> {where( :is_pro => true )}
  scope :cons, -> {where( :is_pro => false )}
  

  def as_json(options={})
    options[:only] ||= Point.my_public_fields
    result = super(options)

    # If anonymous, hide user id
    if (result['hide_name'] && (current_user.nil? || current_user.id != result['user_id']))
      result['user_id'] = -1
    end

    result['includers'] = JSON.parse (result['includers'] || '[]')
    result['includers'].map! {|u| hide_name && u == user_id ? -1 : u}
    result['includers'].map! {|u| "/user/#{u}"}


    # super slow!
    # result['last_inclusion'] = inclusions.count > 0 ? inclusions.order(:created_at).last.created_at.to_i : -1
        
    # result['is_following'] = following current_user

    make_key(result, 'point')
    #result['included_by'] = result['includers']
    #result.delete('includers')
    stubify_field(result, 'proposal')
    stubify_field(result, 'opinion')
    stubify_field(result, 'user')

    if Thread.current[:subdomain].assessment_enabled

      assessment = proposal.assessments.completed.where(:assessable_type => 'Point', :assessable_id => id).first
      result['assessment'] = assessment ? "assessment/#{assessment.id}" : nil
    end

    result
  end

  def publish
    return if self.published
    self.published = true
    recache
    self.save if changed?

    ActiveSupport::Notifications.instrument("point:published", 
      :point => self,
      :current_subdomain => Thread.current[:subdomain]
    )
  end

  # The user is subscribed to the point _implicitly_ if:
  #   • they have included the point
  #   • they have commented on the point
  def following(follower)
    explicit = get_explicit_follow follower #using the Followable polymophic method
    if explicit
      return explicit.follow
    else
      return JSON.parse(includers || '[]').include?(follower.id) \
             || comments.map {|c| c.user_id}.include?(follower.id)
    end
  end

  def followers
    explicit = Follow.where(:followable_type => self.class.name, :followable_id => self.id, :explicit => true)
    explicit_no = explicit.all.select {|f| !f.follow}.map {|f| f.user_id}
    explicit_yes = explicit.all.select {|f| f.follow}.map {|f| f.user}

    candidates = (JSON.parse(includers || '[]') + comments.map {|c| c.user_id}).uniq

    implicit_yes = candidates.select {|u| !explicit_no.include?(u)}.map {|uid| User.find(uid)}

    all_followers = explicit_yes + implicit_yes

    all_followers.uniq
  end


  def category
    is_pro ? 'pro' : 'con'
  end

  def recache
    self.comment_count = comments.count

    # if we just look at self.inclusions, authors of unpublished opinions that
    # included this point will be set as includers
    opinions = Opinion.published \
            .where(:proposal_id => self.proposal_id) \
            .where("user_id IN (?)", self.inclusions.map {|i| i.user_id} ) \
            .select(:stance, :user_id)
 

    self.includers = opinions.map {|x| x.user_id}
    self.num_inclusions = self.includers.length          
    self.last_inclusion = num_inclusions > 0 ? self.inclusions.where("user_id IN (?)", self.includers).order(:created_at).last.created_at.to_i : -1

    ###
    # define cross-spectrum appeal

    if num_inclusions == 0 # special cases
      self.appeal = 0.001
    elsif num_inclusions == 1
      self.appeal = 0.001
    else
      # Compute the variance of the distribution of stances of users
      # including this point. 
      includer_stances = opinions.map {|o| o.stance} 

      n = includer_stances.length
      mean = includer_stances.inject(:+) / n

      variance = 1.0 / n * (includer_stances.map {|v| (v - mean) ** 2 }).inject(:+)
      standard_deviation = Math.sqrt(variance)

      self.appeal = standard_deviation
      self.score = num_inclusions + standard_deviation * num_inclusions
    end

    self.includers = self.includers.to_s

    save(:validate => false) if changed?
  end
        
  def self.update_scores
    Point.published.each {|pnt| pnt.recache }
  end

  def can?(action)
    user = Thread.current[:current_user]

    return true if user.is_admin?
    
    if action == :read
      can?(:update) || (self.published && (self.moderation_status.nil? || self.moderation_status != 0)) || (!self.published && self.user_id.nil?)
    elsif action == :create
      self.proposal.active
    elsif action == :update
      user.id == self.user_id
    elsif action == :destroy      
      can?(:update) && self.inclusions.count < 2
    else
      false
    end
    
  end


end
