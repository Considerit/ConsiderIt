# coding: utf-8
class Point < ActiveRecord::Base
  
  include Followable, Commentable, Moderatable, Assessable
    
  belongs_to :user
  belongs_to :proposal
  has_many :inclusions, :dependent => :destroy
  
  validates :nutshell, :presence => true, :length => { :maximum => 141 }


  before_validation do 
    #self.nutshell = self.nutshell.sanitize
    #self.text = self.text.sanitize

    if self.nutshell.length > 140 
      text << self.nutshell[139..-1]
      self.nutshell = self.nutshell[0..139]
    end

    if self.nutshell.length == 0 && !self.text.nil? && self.text.length > 0
      self.text =  self.text[139..self.text.length]
      self.nutshell = self.text[0..139]
    end

  end

  acts_as_tenant(:account)

  self.moderatable_fields = [:nutshell, :text]
  self.moderatable_objects = lambda {
    Point.joins(:proposal).published.where(:proposals => {:active => true})
  }

  self.assessable_fields = [:nutshell, :text]
  self.assessable_objects = lambda {
    Point.joins(:proposal).published.where(:proposals => {:active => true})
  }

  class_attribute :my_public_fields
  self.my_public_fields = [:comment_count, :created_at, :id, :includers, :is_pro, :moderation_status, :nutshell, :opinion_id, :proposal_id, :published, :score, :text, :user_id, :hide_name, :last_inclusion]

  scope :public_fields, -> {select(self.my_public_fields)}

  scope :named, -> {where( :hide_name => false )}
  scope :published, -> {where( :published => true )}
  scope :viewable, -> {where( 'published=1 AND (moderation_status IS NULL OR moderation_status=1)')}
  
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
    
    #pp self.last_inclusion
    #result['last_inclusion'] = self.last_inclusion
    
    # result['is_following'] = following current_user

    make_key(result, 'point')
    #result['included_by'] = result['includers']
    #result.delete('includers')
    stubify_field(result, 'proposal')
    stubify_field(result, 'opinion')
    stubify_field(result, 'user')

    # for legacy dash support
    result['id'] = id
    
    result
  end

  def only_public_fields
    self.to_json :only => Point.my_public_fields
  end  

  def publish()
    return if self.published
    self.published = true
    self.save

    ActiveSupport::Notifications.instrument("point:published", 
      :point => self,
      :current_tenant => Thread.current[:tenant],
      :mail_options => Thread.current[:mail_options]
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

  def category
    is_pro ? 'pro' : 'con'
  end

  def recache(in_batch = false)
    self.comment_count = comments.count
    if !in_batch
      self.num_inclusions = self.inclusions.count
    end

    self.includers = self.inclusions(:select => [:user_id]).map {|x| x.user_id}.compact.uniq.to_s
    self.last_inclusion = inclusions.count > 0 ? self.inclusions.order(:created_at).last.created_at.to_i : -1

    self.attention = self.num_inclusions


    ###
    # define cross-spectrum appeal

    if num_inclusions == 0 #special cases
      self.appeal = 0.001
    elsif num_inclusions == 1
      self.appeal = 0.001
    else
      # Compute the variance of the distribution of stances of users
      # including this point. We'll only use 3 bins, support / neutral / oppose,
      # for the distribution. The appeal is high when there is low
      # variance (uniform appeal across the spectrum). 
      qry = Opinion.published \
              .where(:proposal_id => self.proposal_id) \
              .where("user_id in (#{self.includers[1..self.includers.length-2]})")
              .group(:stance_segment)
              .select("COUNT(*) AS cnt, opinions.stance_segment")
      includer_stance_distribution = qry.each_with_object({0 => 0, 1 => 0, 2 => 0}) do |row, hash|
        if row.stance_segment == 3
          hash[1] += row.cnt
        elsif row.stance_segment < 3
          hash[0] += row.cnt
        else
          hash[2] += row.cnt
        end
      end
      includer_stance_distribution = includer_stance_distribution.values()
      n = includer_stance_distribution.length
      mean = includer_stance_distribution.inject(:+) / n

      variance = 1.0 / n * (includer_stance_distribution.map {|v| (v - mean) ** 2 }).inject(:+)
      standard_deviation = Math.sqrt(variance) + 1

      self.appeal = num_inclusions / standard_deviation
      self.score = appeal * num_inclusions + num_inclusions
    end


    save(:validate => false) if changed?
  end
        
  def self.update_scores
    Point.all.each {|pnt| pnt.recache }
  end

end
