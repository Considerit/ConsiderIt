class Proposal < ActiveRecord::Base
  has_many :points
  has_many :positions
  has_many :inclusions
  has_many :point_listings
  has_many :point_similarities
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

  def has_admin_privilege(candidate_user, this_session_id, params)
    this_session_id == @session_id || candidate_user && (candidate_user.id == user_id || candidate_user.is_admin?) || (params.has_key?(:admin_id) && params[:admin_id] == admin_id)
  end
end
