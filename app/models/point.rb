class Point < ActiveRecord::Base
  belongs_to :user
  belongs_to :option
  belongs_to :position
  has_many :inclusions
  has_many :point_listings
  
  acts_as_paranoid_versioned
  
  cattr_reader :per_page
  @@per_page = 4  
  
  #TODO: add more scopes http://edgerails.info/articles/what-s-new-in-edge-rails/2010/02/23/the-skinny-on-scopes-formerly-named-scope/index.html
  scope :pros, where( :is_pro => true )
  scope :cons, where( :is_pro => false )
  scope :not_included_by, proc {|user| joins(:inclusions.outer, "AND inclusions.user_id = #{user.id}").where("inclusions.user_id IS NULL") }
  #scope :not_included_by, proc {|user| joins(:inclusions.outer, "AND inclusions.user_id = #{user.id}").where("inclusions.user_id IS NULL") }

  scope :included_by, proc {|user| joins(:inclusions, "AND inclusions.user_id = #{user.id}").where("inclusions.user_id IS NOT NULL") }

end
