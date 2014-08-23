class Inclusion < ActiveRecord::Base
  # has_paper_trail :only => [:point_id, :user_id, :included_as_pro]  
  belongs_to :point, :touch => true
  belongs_to :user
  belongs_to :opinion
  belongs_to :proposal

  acts_as_tenant(:account)
    
  after_save :check_dupes

  #scope :by_user_with_stance, proc {|stance_segment| joins(:opinion).where("opinions.stance_segment=" + stance_segment.to_s) }

  def check_dupes
    user_points    = Inclusion.where(:user_id => self.user_id, :point_id => self.point_id)
    point_opinions = Inclusion.where(:point_id => self.point_id, :opinion_id => self.opinion_id)
    if user_points.length > 1
      raise "This is a duplicate user_point user #{self.user_id} point #{self.point_id} of n=#{user_points.length} #{user_points.map{|i| i.id}}"
    end
    if point_opinions.length > 1
      raise "This is a duplicate point_opinion point #{point_id} user #{opinion_id} of n=#{point_opinions.length}"
    end
  end
  
  def self.find_all_dupes
    for i in Inclusion.all.order(:user_id)
      begin
        i.check_dupes
      rescue
        puts"#{$!}"
      end
    end
    nil
  end
end
