class Proposal < ActiveRecord::Base
  has_many :points, :dependent => :destroy
  has_many :positions, :dependent => :destroy
  has_many :inclusions, :dependent => :destroy
  has_many :point_listings, :dependent => :destroy
  has_many :point_similarities, :dependent => :destroy
  has_many :domain_maps
  belongs_to :user
  
  acts_as_tenant(:account)
  is_trackable
  
  def format_description
    return self.description.split('\n')
  end
  
  def reference
    return "#{category} #{designator}"
  end

  #returns the slug :long_id instead of :id when @proposal passed to e.g. proposal_path
  def to_param
    long_id
  end

  def title(max_len = 140)
    if name
      my_title = name
    elsif description
      my_title = description
    else
      raise 'Name and description nil'
    end

    if my_title.length > 140
      "#{my_title}..."
    else
      my_title
    end
    
  end

  def update_metrics
    self.num_points = points.count
    self.num_pros = points.pros.count
    self.num_cons = points.cons.count
    self.num_comments = 0
    self.num_inclusions = 0
    points.each do |pnt|
      self.num_comments += pnt.comments.count
      self.num_inclusions += pnt.inclusions.count
    end
    self.num_perspectives = positions.published.count
    self.num_unpublished_positions = positions.where(:published, false)
    self.num_supporters = positions.published.where("stance_bucket > ?", 3).count
    self.num_opposers = positions.published.where("stance_bucket < ?", 3).count

    self.num_views = 1
    self.save

  end

  def self.add_long_id
    Proposal.where(:long_id => nil).each do |p|
      p.long_id = SecureRandom.hex(5)
      p.save
    end
  end

  def self.update_scores
    # for now, order by activity; later, incorporate trending    

    Proposal.all.each do |p|
      p.update_metrics

      p.provocative = p.num_perspectives.to_f / (p.num_perspectives + p.num_unpublished_positions)
      p.trending = 0 #support * %support, last 20% of activities)
      p.activity = Math.log2(p.num_perspectives + 1) * Math.log2(p.num_comments + p.num_points + p.num_inclusions + 1)
      
      polarization = p.num_perspectives == 0 ? 1 : p.num_supporters.to_f / p.num_perspectives - 0.5
      p.contested = -4 * polarization ** 2 + 1

      p.save
    end

    true
    #update the relative metrics of each proposal

  end

  def has_admin_privilege(candidate_user, this_session_id, params)
    (session_id && this_session_id == session_id) || (candidate_user && (candidate_user.id == user_id || candidate_user.is_admin?)) || (params.has_key?(:admin_id) && params[:admin_id] == admin_id)
  end
end
