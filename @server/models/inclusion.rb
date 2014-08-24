class Inclusion < ActiveRecord::Base
  # has_paper_trail :only => [:point_id, :user_id, :included_as_pro]  
  belongs_to :point, :touch => true
  belongs_to :user
  belongs_to :proposal

  acts_as_tenant(:account)
    
  after_save :check_dupes

  def check_dupes(purge = false)
    user_points    = Inclusion.where(:user_id => self.user_id, :point_id => self.point_id)
    if user_points.length > 1
      error_str = "#{created_at} This is a duplicate user_point user #{self.user_id} point #{self.point_id} of n=#{user_points.length} #{user_points.map{|i| i.id}}"
      if purge
        user_points.map {|i| i.id}[1..99999999].each do |dup|
          Inclusion.find(dup).destroy
        end

      end
      raise error_str
    end
  end
  
  def self.find_all_dupes(purge = false)
    for i in Inclusion.all.order(:created_at)
      begin
        i.check_dupes purge
      rescue
        puts"#{$!}"
      end
    end
    nil
  end
end
