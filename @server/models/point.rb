# coding: utf-8
class Point < ApplicationRecord
  
  include Moderatable, Notifier, Slideable

  belongs_to :user
  belongs_to :proposal
  has_many :inclusions, :dependent => :destroy
  has_many :comments, :dependent=>:destroy  
  
  validates :nutshell, :presence => true, :length => { :maximum => 181 }


  before_validation do 
    #self.nutshell = sanitize_helper self.nutshell
    #self.text = sanitize_helper self.text


    if self.nutshell.length > 180 
      self.text = self.text ? "#{self.nutshell[179..-1]} #{self.text}" : self.nutshell[179..-1]
      self.nutshell = self.nutshell[0..179]
    end

    if self.nutshell.length == 0 && !self.text.nil? && self.text.length > 0
      self.text =  self.text[179..self.text.length]
      self.nutshell = self.text[0..179]
    end

  end

  acts_as_tenant :subdomain

  class_attribute :my_public_fields
  self.my_public_fields = [:comment_count, :created_at, :updated_at, :id, :is_pro, :nutshell, :proposal_id, :published, :text, :user_id, :hide_name, :last_inclusion, :subdomain_id]

  scope :public_fields, -> {select(self.my_public_fields)}

  scope :named, -> {where( :hide_name => false )}
  scope :published, -> {where( :published => true )}
  
  scope :pros, -> {where( :is_pro => true )}
  scope :cons, -> {where( :is_pro => false )}
  
  def roles
    self.proposal.roles
  end

  def as_json(options={})
    options[:only] ||= Point.my_public_fields
    result = super(options)

    # If anonymous, hide user id
    if (result['hide_name'] && (current_user.nil? || current_user.id != result['user_id']))
      result['user_id'] = -1
    end
        
    make_key(result, 'point')
    stubify_field(result, 'proposal')
    stubify_field(result, 'user')

    # Find an existing opinion for this user
    user = current_user
    if current_user.logged_in?
      your_opinion = self.opinions.where(:user_id => user.id).order('id DESC')
      if your_opinion.length > 1
        pp "Duplicate opinions for user #{current_user}: #{your_opinion.map {|o| o.id} }!"
      end      
      your_opinion = your_opinion.first
    else 
      your_opinion = nil 
    end

    if your_opinion
      result['your_opinion'] = your_opinion 
    else 
      result['your_opinion'] = {
        stance: 0,
        user: "/user/#{current_user.id}",
        statement: self.key,
        published: false
      }

    end

    o = ActiveRecord::Base.connection.execute """\
      SELECT created_at, id, stance, user_id, updated_at, statement_id, statement_type
          FROM opinions 
          WHERE subdomain_id=#{self.subdomain_id} AND
                statement_type='Point' AND
                statement_id=#{self.id} AND 
                published=1;
      """

    result['opinions'] = o.map do |op|
      r = {
        key: "/opinion/#{op[1]}",
        # created_at: op[0],
        updated_at: op[4],
        # proposal: "/proposal/#{op[3]}",
        user: "/user/#{op[3]}",
        # published: true,
        stance: op[2].to_f,
        statement: "/#{op[6].downcase}/#{op[5]}"        
      }

      r 
    end 



    result
  end

  def self.get_all
    if current_subdomain.moderation_policy == 1
      moderation_status_check = 'moderation_status=1'
    else 
      moderation_status_check = '(moderation_status IS NULL OR moderation_status=1)'
    end

    pointz = Point.where("(published=1 AND #{moderation_status_check}) OR user_id=#{current_user.id}")
    pointz = pointz.public_fields.map {|p| p.as_json}
    data = {
      key: '/points',
      points: pointz
    }
    data 
  end

  def publish
    return if self.published
    self.published = true
    recache
    self.save if changed?

    Notifier.notify_parties 'new', self
    notify_moderator

  end

  def category
    is_pro ? 'pro' : 'con'
  end

  def key 
    "/point/#{self.id}"
  end

  def recache
    self.comment_count = comments.count

    # ###
    # # define cross-spectrum appeal
    # if updated_includers.length == 0 # special cases
    #   self.appeal = 0.001
    # elsif updated_includers.length == 1
    #   self.appeal = 0.001
    # else
    #   # Compute the variance of the distribution of stances of users
    #   # including this point. 
    #   includer_stances = opinions.map {|o| o.stance} 

    #   n = includer_stances.length
    #   mean = includer_stances.inject(:+) / n

    #   variance = 1.0 / n * (includer_stances.map {|v| (v - mean) ** 2 }).inject(:+)
    #   standard_deviation = Math.sqrt(variance)

    #   self.appeal = standard_deviation
    #   self.score = updated_includers.length + standard_deviation * updated_includers.length
    # end

    # self.includers = updated_includers

    self.last_inclusion = self.opinions.length > 0 ? self.opinions.order(:created_at).last.created_at.to_i : -1

    if changed?
      save(:validate => false) 
      dirty_key self.key
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
