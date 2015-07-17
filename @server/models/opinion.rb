class Opinion < ActiveRecord::Base
  belongs_to :user
  belongs_to :proposal, :touch => true 
  
  include Notifier

  acts_as_tenant :subdomain

  scope :published, -> {where( :published => true )}
  scope :public_fields, -> {select( [:created_at, :updated_at, :id, :proposal_id, :stance, :user_id, :point_inclusions, :published] )}

  def as_json(options={})
    pubs = ['created_at', 'updated_at', 'id', 'point_inclusions',
            'proposal_id', 'stance', 'user_id',
            'published']

    result = super(options)
    result = result.select{|k,v| pubs.include? k}

    make_key(result, 'opinion')
    stubify_field(result, 'user')
    stubify_field(result, 'proposal')
    result['point_inclusions'] = JSON.parse (result['point_inclusions'] || '[]')
    result['point_inclusions'].map! {|p| "/point/#{p}"}
    result
  end

  def self.get_or_make(proposal)
    # Each (user,proposal) should have only one opinion.
    user = current_user
    
    # First try to find a published opinion for this user
    your_opinion = Opinion.where(:proposal_id => proposal.id, 
                                 :user => user)
    if your_opinion.length > 1
      raise "Duplicate opinions for user #{user}: #{your_opinion.map {|o| o.id} }!"
    end
    your_opinion = your_opinion.first

    # Otherwise create one
    if your_opinion.nil?
      your_opinion = Opinion.create(:proposal_id => proposal.id,
                                    :user => user ? user : nil,
                                    :subdomain_id => current_subdomain.id,
                                    :published => false,
                                    :stance => 0,
                                    :point_inclusions => '[]',
                                   )
    end
    your_opinion
  end

  def publish(previously_published)
    return if self.published

    self.published = true
    recache
    self.save if changed?

    # When we publish an opinion, all the points the user wrote on
    # this opinion/proposal become published too
    Point.where(:user_id => self.user_id,
                :proposal_id => self.proposal_id).each {|p| p.publish()}

    # New opinion means the proposal needs to be re-fetched so that
    # it includes it in its list of stuff
    dirty_key "/page/#{Proposal.find(proposal_id).slug}"

    # Need to recache the included points so that the user is shown as an official
    # includer of this point now that the opinion is being published. 
    inclusions.each do |inc|
      inc.point.recache
    end

    if !previously_published
      Notifier.create_notification 'new', self
    end

    current_user.update_subscription_key(proposal.key, 'watched', :force => false)
    dirty_key "/current_user"

  end

  def update_inclusions (points_to_include)
    points_already_included = inclusions.map {|i| i.point_id}.compact
    points_to_exclude = points_already_included.select {|point_id| not points_to_include.include? point_id}
    points_to_add    = points_to_include.select {|p_id| not points_already_included.include? p_id }

    puts("Excluding points #{points_to_exclude}, including points #{points_to_add}")

    # Delete goners
    points_to_exclude.each do |point_id|
      self.exclude point_id
    end
    
    # Add newbies
    points_to_add.each do |point_id|
      self.include point_id
    end

    # Return the points that were not touched in this process
    # These points are used in the absorb method. 
    points_to_include.select {|p_id| points_already_included.include? p_id }
  end

  def include(point)
    if not point.is_a? Point
      point = Point.find point
    end

    user = User.find(self.user_id)

    if !point.id
      Rails.logger.error "TRYING TO INCLUDE A POINT THAT DOESN'T EXIST"
      return
    end    
    
    if user.inclusions.where( :point_id => point.id ).count > 0
      Rails.logger.error "Including a point (#{point.id}) for user #{self.user_id} twice!'"
      return
    end

    attrs = { 
      :point_id => point.id,
      :user_id => self.user_id,
      :proposal_id => self.proposal_id,
      :subdomain_id => current_subdomain.id
    }
    Inclusion.create! attrs

    point.recache
    self.recache

    dirty_key("/point/#{point.id}")
    dirty_key("/opinion/#{self.id}")
  end

  def exclude(point)
    if not point.is_a? Point
      point = Point.find point
    end
    dirty_key("/point/#{point.id}")
    dirty_key("/opinion/#{self.id}")

    user = User.find(self.user_id)
    inclusion = user.inclusions.find_by_point_id point.id

    inclusion.destroy
    point.recache
    self.recache
  end
  
  def absorb( opinion, absorb_user = false)

    # First record everything we're dirtying
    dirty_key("/opinion/#{id}")
    dirty_key("/page/#{Proposal.find(proposal_id).slug}")    

    # If we're absorbing the Opinion's user as well
    if absorb_user
      puts("Changing user for Opinion #{id} to #{opinion.user_id}")

      # We only have to update inclusions if the user is changing because
      # inclusions are identified by (proposal_id, user_id), not by Opinion.
      new_inclusions = self.proposal.inclusions.where(:user_id => opinion.user_id).where('point_id IS NOT NULL')
      all_inclusions = ( inclusions.where('point_id IS NOT NULL').map{|i| i.point.id} \
                    + new_inclusions.map{|i| i.point.id}).uniq

      # BUG: There is a strange bug we can't find where inclusion.point_id can
      # get set to null. The code above has been null guarded. 
      # This is an attempt to gather more data on it. 
      if inclusions.where('point_id IS NULL').count > 0 
        begin 
          raise "We have a null point_id for an inclusion!"
        rescue => e
          ExceptionNotifier.notify_exception e, :env => request.env
        end
      end

      proposal.inclusions.where(:user_id => self.user_id).destroy_all

      self.user_id = opinion.user_id # Do this after getting all_inclusions, but before update_inclusions.
      not_recached = self.update_inclusions(all_inclusions) # And this will recached
      not_recached.each do |pnt_id|
        Point.find(pnt_id).recache
      end
    end

    puts("Absorbing opinion #{opinion.id} into #{self.id}")

    # Copy the stance of the opinion if the opinion is older
    # (Picking the older one because of a bug where if you
    # login on a proposal page, it will replace your old opinion
    # with the new neutral one)
    if opinion.updated_at < updated_at && opinion.published
      self.stance = opinion.stance
    end

    # If something was published, ensure everything is published
    self.publish(opinion.published) if self.published or opinion.published

    opinion.destroy()
    recache

  end

  def recache
    self.point_inclusions = inclusions.select(:point_id).map {|x| x.point_id }.uniq.compact.to_s
    self.save
  end

  def inclusions
    Inclusion.where(:proposal_id => proposal_id, :user_id => user_id).where('point_id is not NULL')
  end

  # This is a maintenance function.  You shouldn't need to run it
  # anymore, because the database shouldn't contain duplicate opinions
  # anymore.
  def self.remove_duplicate_opinions
    User.find_each do |u|
      proposals = u.opinions.map {|p| p.proposal_id}.uniq
      proposals.each do |prop|
        ops = u.opinions.where(:proposal_id => prop)
        # Let's find the most recent
        ops = ops.sort {|a,b| a.updated_at <=> b.updated_at}
        # And purge all but the last
        pp("We found #{ops.length-1} duplicates for user #{u.id}")
        ops.each do |op|
          if op.id != ops.last.id
            pp("We are deleting opinion #{op.id}, cause it is not the most recent: #{ops.last.id}.")
            op.delete
          end
        end
      end
    end

    # And cause I want this too
    Point.all.each do |p|
      if p.published
        puts("Fixing #{p.id}")
      end
      p.recache(true)
    end
    'done'
  end

  def self.purge
    #Opinion.where('user_id IS NULL').destroy_all
    
    User.where('registered=true').each do |u|
      proposals = u.opinions.map {|p| p.proposal_id}.uniq
      proposals.each do |prop|
        pos = u.opinions.where(:proposal_id => prop)
        if pos.where(:published => true).count > 1
          last = pos.order(:updated_at).last
          pos.where('id != (?)', last.id).each do |p|
            p.published = false
            p.save
          end
        end
      end
    end
  end

end



