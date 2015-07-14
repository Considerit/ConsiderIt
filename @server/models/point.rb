# coding: utf-8
class Point < ActiveRecord::Base
  
  include Moderatable, Assessable, Notifier
    
  belongs_to :user
  belongs_to :proposal
  has_many :inclusions, :dependent => :destroy
  has_many :comments, :dependent=>:destroy  
  
  validates :nutshell, :presence => true, :length => { :maximum => 141 }


  before_validation do 
    #self.nutshell = self.nutshell.sanitize
    #self.text = self.text.sanitize

    if self.nutshell.length > 180 
      self.text = self.text ? "#{self.nutshell[139..-1]} #{self.text}" : self.nutshell[139..-1]
      self.nutshell = self.nutshell[0..179]
    end

    if self.nutshell.length == 0 && !self.text.nil? && self.text.length > 0
      self.text =  self.text[179..self.text.length]
      self.nutshell = self.text[0..179]
    end

  end

  acts_as_tenant :subdomain

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
        
    make_key(result, 'point')
    #result['included_by'] = result['includers']
    #result.delete('includers')
    stubify_field(result, 'proposal')
    stubify_field(result, 'opinion')
    stubify_field(result, 'user')

    if current_subdomain.assessment_enabled

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

    Notifier.create_notification 'new', self
    notify_moderator

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

    updated_includers = opinions.map {|x| x.user_id}

    ###
    # define cross-spectrum appeal
    if updated_includers.length == 0 # special cases
      self.appeal = 0.001
    elsif updated_includers.length == 1
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
      self.score = updated_includers.length + standard_deviation * updated_includers.length
    end

    self.includers = updated_includers.to_s
    self.num_inclusions = updated_includers.length
    self.last_inclusion = updated_includers.length > 0 ? self.inclusions.where("user_id IN (?)", updated_includers).order(:created_at).last.created_at.to_i : -1

    if changed?
      save(:validate => false) 
      dirty_key "/point/#{self.id}"
    end
  end
        
  def self.update_scores
    Point.published.each {|pnt| pnt.recache }
  end

  def title(max_len = 180)

    if nutshell.length > max_len
      "#{nutshell[0..max_len]}..."
    else
      nutshell
    end
    
  end

end
