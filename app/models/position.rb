class Position < ActiveRecord::Base
  belongs_to :user
  belongs_to :proposal, :touch => true 
  has_many :inclusions
  has_many :points
  has_many :point_listings
  has_many :comments, :as => :commentable, :dependent => :destroy
  
  has_paper_trail
  is_commentable
  is_trackable
  is_followable

  acts_as_tenant(:account)

  scope :published, -> {where( :published => true )}
  scope :public_fields, -> {select( [:long_id, :created_at, :updated_at, :id, :point_inclusions, :proposal_id, :stance, :stance_bucket, :user_id, :explanation, :published])}

  before_save do 
    self.explanation = Sanitize.clean(self.explanation, Sanitize::Config::RELAXED)
    self.stance_bucket = Position.get_bucket(self.stance)
  end 

  def subsume( subsumed_position )
    subsumed_position.point_listings.update_all({:user_id => user_id, :position_id => id})
    subsumed_position.points.update_all({:user_id => user_id, :position_id => id})
    subsumed_position.inclusions.update_all({:user_id => user_id, :position_id => id})
    subsumed_position.comments.update_all({:commentable_id => id})
    subsumed_position.published = false
    subsumed_position.save
  end

  def self.get_bucket(value)
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
    case stance_bucket
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
    case stance_bucket
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
    User.find_each do |u|
      proposals = u.positions.map {|p| p.proposal_id}.uniq
      proposals.each do |prop|
        pos = u.positions.where(:proposal_id => prop)
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



