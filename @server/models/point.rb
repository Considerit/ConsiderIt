# coding: utf-8
class Point < ApplicationRecord
  
  include Moderatable, Notifier
    
  belongs_to :user
  belongs_to :proposal
  has_many :inclusions, :dependent => :destroy
  has_many :comments, :dependent=>:destroy  
  
  validates :nutshell, :presence => true, :length => { :maximum => 181 }


  before_validation do 
    if self.nutshell.length > 180 
      self.text = self.text ? "#{self.nutshell[179..-1]} #{self.text}" : self.nutshell[179..-1]
      self.nutshell = self.nutshell[0..179]
    end

    if self.nutshell.length == 0 && self.text && self.text.length > 0
      self.nutshell = self.text[0..179]

      if self.text.length > 179
        self.text =  self.text[179..self.text.length]
      else
        self.text = ""
      end

    end

  end

  before_save do 
    self.nutshell = sanitize_helper(self.nutshell) if self.nutshell
    self.text = sanitize_helper(self.text) if self.text
    self.includers = sanitize_json(self.includers) if self.includers
  end


  acts_as_tenant :subdomain

  class_attribute :my_public_fields
  self.my_public_fields = [:comment_count, :created_at, :updated_at, :id, :includers, :is_pro, :nutshell, :proposal_id, :published, :text, :user_id, :hide_name, :last_inclusion, :subdomain_id]

  scope :public_fields, -> {select(self.my_public_fields)}

  scope :named, -> {where( :hide_name => false )}
  scope :published, -> {where( :published => true )}
  
  scope :pros, -> {where( :is_pro => true )}
  scope :cons, -> {where( :is_pro => false )}
  

  def self.anonymize_json(json, anonymize_everything, active_user=nil)
    if !active_user
      active_user = current_user
    end

    id = key_id(json['user'])
    if (anonymize_everything || (json["hide_name"] && json["hide_name"] != 0)) && active_user.id != id
      json['user'] = "/user/#{User.anonymized_id(id)}"
    end

    if json['includers']
      if json['includers'].length > 0
        json['includers'].map! do |u|
          id = u['id']
          if (anonymize_everything || u['hide_name'] && json["hide_name"] != 0) && (!active_user || active_user.id != id )
            id = User.anonymized_id(id)
          end
          "/user/#{id}"
        end
      end
    else 
      json['includers'] = []
    end

    json
  end

  def as_json(options={})
    options[:only] ||= Point.my_public_fields
    result = super(options)

    result["created_at"] = result["created_at"].to_time.utc
    result["updated_at"] = result["updated_at"].to_time.utc

    make_key(result, 'point')
    stubify_field(result, 'proposal')
    stubify_field(result, 'user')

    anonymize_everything = current_subdomain.customization_json['anonymize_everything']
    result = Point.anonymize_json(result, anonymize_everything)

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

  def set_comment_count 
    self.comment_count = 0 
    self.comments.each do |c|
      if c.okay_to_email_notification
        self.comment_count += 1
      end
    end
    if changed?
      self.save
    end
  end

  def recache
    set_comment_count

    self.includers = self.inclusions.map do |x|
      {'id' => x.user_id, 'hide_name' => x.opinion.hide_name}
    end

    # ###
    # # define cross-spectrum appeal
    # if self.includers.length == 0 # special cases
    #   self.appeal = 0.001
    # elsif self.includers.length == 1
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
    #   self.score = self.includers.length + standard_deviation * self.includers.length
    # end


    self.last_inclusion = self.includers.length > 0 ? self.inclusions.order(:created_at).last.created_at.to_i : -1

    if changed?
      save(:validate => false) 
      dirty_key "/point/#{self.id}"
      Proposal.clear_cache(self.subdomain)      
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


  def self.update_inclusions_all
    sql = """
      UPDATE points p
      SET includers = COALESCE(
        (
          SELECT JSON_ARRAYAGG(
              JSON_OBJECT(
                'id', i.user_id,
                'hide_name', o.hide_name
              )
            )
          FROM inclusions i
          JOIN opinions o ON i.proposal_id=o.proposal_id AND i.user_id=o.user_id
          WHERE i.point_id = p.id
        ), 
        '[]'
      );
    """    
    ActiveRecord::Base.connection.execute(sql)
  end

end
