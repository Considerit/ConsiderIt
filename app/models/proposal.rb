class Proposal < ActiveRecord::Base
  has_many :points, :dependent => :destroy
  has_many :positions, :dependent => :destroy
  has_many :inclusions, :dependent => :destroy
  has_many :point_listings, :dependent => :destroy
  has_many :point_similarities, :dependent => :destroy
  has_many :domain_maps
  belongs_to :user
  
  acts_as_tenant(:account)
  
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
    self.num_perspectives = positions.count
    self.num_supporters = positions.where("stance_bucket > ?", 3).count
    self.num_opposers = positions.where("stance_bucket < ?", 3).count

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

    Proposal.order(:score).each do |p|
      p.update_metrics
      p.score = (p.num_points + p.num_comments + p.num_inclusions) * Math.log2(p.num_perspectives + 1)  
      p.save
    end

    true
    #update the relative metrics of each proposal
    #Account.all do |acnt|
  end

  def has_admin_privilege(candidate_user, this_session_id, params)
    this_session_id == session_id || candidate_user && (candidate_user.id == user_id || candidate_user.is_admin?) || (params.has_key?(:admin_id) && params[:admin_id] == admin_id)
  end
end
