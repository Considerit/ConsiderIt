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
  self.my_public_fields = [:comment_count, :created_at, :id, :includers, :is_pro, :moderation_status, :nutshell, :opinion_id, :proposal_id, :published, :score, :text, :user_id, :hide_name]

  scope :public_fields, -> {select(self.my_public_fields)}

  scope :named, -> {where( :hide_name => false )}
  scope :published, -> {where( :published => true )}
  scope :viewable, -> {where( 'published=1 AND (moderation_status IS NULL OR moderation_status=1)')}
  
  scope :pros, -> {where( :is_pro => true )}
  scope :cons, -> {where( :is_pro => false )}
  

  def as_json(options={}, current_user=nil)
    options[:only] ||= Point.my_public_fields
    result = super(options)

    # If anonymous, hide user id
    if (result['hide_name'] && (current_user.nil? || current_user.id != result['user_id']))
      result['user_id'] = -1
    end

    result['includers'] = JSON.parse (result['includers'] || '[]')
    result['includers'].map! {|p| "/user/#{p}"}
    result['last_inclusion'] = inclusions.count > 0 ? inclusions.last.created_at.to_i : -1
    make_key(result, 'point')
    #result['included_by'] = result['includers']
    #result.delete('includers')
    stubify_field(result, 'proposal')
    stubify_field(result, 'opinion')
    stubify_field(result, 'user')
    result
  end

  def only_public_fields
    self.to_json :only => Point.my_public_fields
  end  

  def publish()
    self.published = true
    self.save

    ActiveSupport::Notifications.instrument("point:published", 
      :point => self,
      :current_tenant => Thread.current[:tenant],
      :mail_options => Thread.current[:mail_options]
    )
  end

  def seen_by(user)
    # unimplemented. It was:
    # session[proposal.id][:viewed_points].push([point.id, 7]) # own point has been seen
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

    define_appeal
    define_attention
        
    save(:validate => false) if changed?
  end
  
  def define_appeal
    e = entropy
    if e.nil? or self.num_inclusions.nil?
      self.appeal = 0
      self.divisiveness = 0
    else
      self.appeal = e * self.num_inclusions
      self.divisiveness = (1 - e) * self.num_inclusions      
    end
  end
  
  def define_attention
    self.attention = self.num_inclusions
  end
    
  # Class method for iterating through all Points to 
  # update their relative scores. Very computationally
  # expensive, so should only be called periodically by cron job
  def self.update_relative_scores
    num_inclusions_per_point = {}

    Inclusion.select("COUNT(*) AS cnt, point_id AS pnt").group(:point_id).each do |row|
      num_inclusions_per_point[row.pnt.to_i] = row.cnt.to_i
    end

    Account.find_each do |accnt|
      accnt.proposals.select(:id).each do |proposal|
        
        # Point ranking across the metrics is done separately for pros and cons,
        # fixed on a particular Proposal
        point_groups = [
          proposal.points.viewable.pros.select("id, appeal, attention, score, num_inclusions").to_a,
          proposal.points.viewable.cons.select("id, appeal, attention, score, num_inclusions").to_a
        ]

        point_groups.each do |group|        
          relative_scores = {}

          group.each do |pnt|
            pnt.num_inclusions = num_inclusions_per_point.has_key?(pnt.id) ? num_inclusions_per_point[pnt.id] : 0
            pnt.recache(true)
            relative_scores[pnt.id] = []
          end
          
          [:appeal.to_s, :attention.to_s].each do |metric|
            
            # descending sort of points by current metric
            group.sort! {|x,y| y.attributes[metric] <=> x.attributes[metric]}
            
            # now we'll compute the relative percentile ranking for the metric for each point (1=highest, 0 lowest)
            cur_val = nil
            rank = nil
            group.each_with_index do |pnt, idx|
              if !cur_val || pnt.attributes[metric] < cur_val
                rank = idx.to_f
                cur_val = pnt.attributes[metric]
              end
              relative_scores[pnt.id].push( 1 - rank / group.length )
            end
          end
          
          group.each do |pnt|
            pnt.score = relative_scores[pnt.id].inject(:+) / relative_scores[pnt.id].length
            pnt.save(:validate => false)
          end
                              
        end
      end
    end    
  end
  

protected
  def entropy
    
    distribution = Array.new(5, 0.0001)

    qry = inclusions.joins("INNER JOIN opinions ON opinions.user_id=inclusions.user_id AND opinions.proposal_id=inclusions.proposal_id") \
                    .where("opinions.published=1" )                                      \
                    .group('opinions.stance_segment')                                    \
                    .select("COUNT(*) AS cnt, opinions.stance_segment")
                        
    # get the number of inclusions per stance group
    qry.each do |row|
      # collapse strong and moderate support/oppose to make more fair distribution
      if row.stance_segment == '0'
        row.stance_segment = '1'
      elsif row.stance_segment == '6'
        row.stance_segment = '5'
      end
      begin
        distribution[row.stance_segment.to_i - 1] += row.cnt.to_i    
      rescue
        'error'
      end
       
    end

    e = 0
    total = distribution.inject(:+)
    if total > 0
      distribution.each do |val|
        if val > 0
          # p is the probability of seeing this stance in the distribution
          p = 1.0 * val / total
          e -= p * Math.log(p, 5)
        end
      end
    end
    e    
  end
end
