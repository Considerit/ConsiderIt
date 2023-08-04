class Inclusion < ApplicationRecord
  belongs_to :point, :touch => true
  belongs_to :user
  belongs_to :proposal

  acts_as_tenant :subdomain
    
  after_save :check_dupes

  def opinion

    if !self.user or !self.proposal
      pp 'No user or proposal for', self
      return nil
    end

    opinions = self.user.opinions.where(:proposal => self.proposal.id)

    if opinions.count == 0
      pp 'No onpinions for', self
      return nil
    end

    if opinions.count > 1
      pp self.point
      # raise "multiple opinions" unless opinions.count <= 1
    end

    if !opinions.first.published
      pp self.point
      # raise "unpublished" unless opinions.first.published
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
    pp "purging all inclusion dupes"
    Inclusion.find_all_dupes(purge)
    pp "purging all orphaned inclusions"

    if purge
      purge_orphans = ["""
        CREATE TEMPORARY TABLE temp_ids AS
        SELECT inc.id
        FROM inclusions inc, opinions o, proposals prop, users u
        WHERE u.id=inc.user_id AND prop.id=inc.proposal_id AND 
              o.proposal_id = inc.proposal_id AND o.user_id = inc.user_id;""",
        "DELETE FROM inclusions WHERE id NOT IN (SELECT id FROM temp_ids);",
        "DROP TEMPORARY TABLE temp_ids;"
      ]

      purge_orphans.each do |sql|
        ActiveRecord::Base.connection.execute(sql)
      end
    else
      for i in Inclusion.all.order(:created_at)
        o = i.opinion
        if !o
          pp "Orphaned inclusion", i
          if purge
            i.destroy!
          end
          orphans += 1
        end
        
      end
    end
  end


end
