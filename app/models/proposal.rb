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
  
end
