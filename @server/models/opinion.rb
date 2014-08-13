class Opinion < ActiveRecord::Base
  belongs_to :user
  belongs_to :proposal, :touch => true 
  has_many :inclusions
  has_many :points
  has_many :point_listings
  has_many :comments, :as => :commentable, :dependent => :destroy
  
  # has_paper_trail

  include Trackable, Followable, Commentable

  acts_as_tenant(:account)

  _public_fields = 

  scope :published, -> {where( :published => true )}
  scope :public_fields, -> {select( [:long_id, :created_at, :updated_at, :id, :point_inclusions, :proposal_id, :stance, :stance_segment, :user_id, :explanation, :published] )}

  before_save do 
    self.explanation = self.explanation.sanitize if self.explanation
    self.stance_segment = Opinion.get_segment(self.stance)
  end 

  def as_json(options={})
    pubs = ['long_id', 'created_at', 'updated_at', 'id', 'point_inclusions',
            'proposal_id', 'stance', 'stance_segment', 'user_id', 'explanation',
            'published']

    result = super(options)
    result = result.select{|k,v| pubs.include? k}

    make_key(result, 'opinion')
    stubify_field(result, 'user')
    stubify_field(result, 'proposal')
    result['point_inclusions'] = JSON.parse (result['point_inclusions'] || '[]')
    result['point_inclusions'].map! {|p| "/point/#{p}"}
    result.delete('long_id')
    result
  end

  def self.get_or_make(proposal, user, tenant)
    your_opinion = Opinion.where(:proposal_id => proposal.id, 
                                 :user_id => user,
                                 :published => true).first
    if not your_opinion
      # Because there seem to be unpublished opinions sometimes... we
      # should remove these though
      your_opinion = Opinion.where(:proposal_id => proposal.id, 
                                   :user_id => user,
                                   :published => false).first
    end
    if not your_opinion
      your_opinion = Opinion.create(:proposal_id => proposal.id,
                                    :user_id => user ? user : nil,
                                    :long_id => proposal.long_id,
                                    :account_id => tenant.id,
                                    :published => false,
                                    :stance => 0,
                                    :point_inclusions => '[]',
                                    :explanation => ''
                                   )
    end
    your_opinion
  end
    
  def include(point, tenant)
    point_id = (point.is_a?(Point) && point.id) || point

    if Inclusion.where( :point_id => point_id, :user_id => self.user_id ).count !=0
      raise 'Including a point twice!'
    end
    
    attrs = { 
      :point_id => point_id,
      :user_id => self.user_id,
      :opinion_id => self.id,
      :proposal_id => self.proposal_id,
      :account_id => tenant.id
    }
          
    Inclusion.create! ActionController::Parameters.new(attrs).permit!
    self.update_inclusions()
  end    
  def subsume( subsumed_opinion )
    subsumed_opinion.point_listings.update_all({:user_id => user_id, :opinion_id => id})
    subsumed_opinion.points.update_all({:user_id => user_id, :opinion_id => id})
    subsumed_opinion.inclusions.update_all({:user_id => user_id, :opinion_id => id})
    subsumed_opinion.comments.update_all({:commentable_id => id})
    subsumed_opinion.published = false
    subsumed_opinion.save
  end

  def update_inclusions
    inclusions = Inclusion.where(:user_id => self.user_id, :proposal_id => self.proposal_id).select(:point_id)

    self.point_inclusions = inclusions.map {|x| x.point_id }.uniq.compact.to_s
    self.save
  end

  def self.get_segment(value)
    if value == -1
      return 0
    elsif value == 1
      return 6
    elsif value <= 0.05 && value >= -0.05
      return 3
    elsif value >= 0.5
      return 5
    elsif value <= -0.5
      return 1
    elsif value >= 0.05
      return 4
    elsif value <= -0.05
      return 2
    end   
  end

  def stance_name
    case stance_segment
      when 0
        return "strong oppose"
      when 1
        return "oppose"
      when 2
        return "weak oppose"
      when 3
        return "undecided"
      when 4
        return "weak support"
      when 5
        return "support"
      when 6
        return "strong support"
    end
  end

  def stance_name_singular
    case stance_segment
      when 0
        return "strongly opposes"
      when 1
        return "opposes"
      when 2
        return "weakly opposes"
      when 3
        return "is neutral about"
      when 4
        return "weakly supports"
      when 5
        return "supports"
      when 6
        return "strongly supports"
    end
  end

  def self.purge
    Opinion.where('user_id IS NULL').destroy_all
    
    User.find_each do |u|
      proposals = u.opinions.map {|p| p.proposal_id}.uniq
      proposals.each do |prop|
        pos = u.opinions.where(:proposal_id => prop)
        if pos.where(:published => true).count > 1
          last = pos.order(:updated_at).last
          pos.where('id != (?)', last.id).each do |p|
            p.published = false
            p.save
          end
        end
      end
    end
  end


end



