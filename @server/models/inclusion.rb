class Inclusion < ApplicationRecord
  belongs_to :point, :touch => true
  belongs_to :user
  belongs_to :proposal

  acts_as_tenant :subdomain
    
  after_save :check_dupes

  def opinion

    if !self.user or !self.proposal
      return nil
    end

    opinions = self.user.opinions.where(:proposal => self.proposal.id)

    if opinions.count == 0
      return nil
    end

    if opinions.count > 1
      pp self.point
      raise "multiple opinions" unless opinions.count <= 1
    end

    if !opinions.first.published
      pp self.point
      raise "unpublished" unless opinions.first.published
    end 

    opinions.first
  end


  def check_dupes(purge = true)
    user_points    = Inclusion.where(:user_id => self.user_id, :point_id => self.point_id)
    if user_points.length > 1
      error_str = "#{created_at} This is a duplicate user #{self.user_id} point #{self.point_id} of n=#{user_points.length} #{user_points.map{|i| i.id}}"
      if purge
        user_points.map {|i| i.id}[1..99999999].each do |dup|
          Inclusion.find(dup).destroy
        end
      end
      raise error_str
    end
  end
  
  def self.find_all_dupes(purge = false)
    dupe_groups = Inclusion.group(:user_id, :point_id).having('count(id) > 1').count

    dupe_groups.each do |keys, count|
      user_id, point_id = keys
      # find duplicates for this user_id and point_id
      duplicates = Inclusion.where(user_id: user_id, point_id: point_id)

      pp "Duplicates", duplicates
      if purge
        # Keep one instance and destroy the others
        duplicates.drop(1).each(&:destroy)
      else
        # You can do something else with duplicates here if you like
      end
    end
  end

  def self.integrity_check(purge=false)
    Inclusion.find_all_dupes(purge)
    for i in Inclusion.all.order(:created_at)
      o = i.opinion
      if !o
        pp "Orphaned inclusion", i
        if purge
          i.destroy!
        end
      end
    end
  end


end
