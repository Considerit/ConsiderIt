class PointListing < ActiveRecord::Base
  belongs_to :proposal
  belongs_to :opinion
  belongs_to :point
  belongs_to :user

  acts_as_tenant(:account)
  
  #scope :by_user_with_stance, proc {|stance_segment| joins(:opinion).where("opinions.stance_segment=" + stance_segment.to_s ) }

  # Collapses PointListings 
  def self.warehouse
    to_delete = []

    ActiveRecord::Base.connection.execute "DELETE FROM point_listings WHERE point_listings.point_id NOT IN (SELECT id FROM points)"

    Point.find_each do |pnt|
      users = pnt.point_listings(:select => [:user_id]).map {|x| x.user_id}.uniq.compact

      users.each do |u|
        l = pnt.point_listings.where(:user_id => u)
        if l.count > 1
          lss = l.to_a
          num_views = lss.map {|x| x.count}.inject(0, :+)
          if lss[0].count != num_views
            lss[0].count = num_views
            lss[0].save
          end
          to_delete += lss[1..lss.length]
        end
      end
    end

    #pp to_delete.length
    if to_delete.count > 0 
      ActiveRecord::Base.connection.execute("DELETE FROM point_listings WHERE id in (#{to_delete.map{|l| l.id}.join(',')})")
    end
    ActiveRecord::Base.connection.execute "UPDATE point_listings SET account_id=(SELECT account_id FROM points WHERE point_listings.point_id=points.id)"
    
  end
end
