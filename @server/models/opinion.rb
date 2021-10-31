class Opinion < ApplicationRecord
  belongs_to :user
  belongs_to :statement, :polymorphic => true, :touch => true
  
  include Notifier

  acts_as_tenant :subdomain

  scope :published, -> {where( :published => true )}
  scope :public_fields, -> {select( [:created_at, :updated_at, :id, :statement_id, :statement_type, :stance, :user_id, :point_inclusions, :published, :subdomain_id] )}

  scope :of_proposals, -> {where(:statement_type => 'Proposal')}

  def as_json(options={})
    pubs = ['created_at', 'updated_at', 'id', 'point_inclusions',
            'stance', 'user_id', 'published']

    result = super(options)
    result = result.select{|k,v| pubs.include? k}

    make_key(result, 'opinion')
    stubify_field(result, 'user')
    result['statement'] = "/#{self.statement_type.downcase}/#{self.statement_id}"
    result['point_inclusions'] = result['point_inclusions'] || []
    result['point_inclusions'].map! {|p| "/point/#{p}"}

    if self.explanation
      result['explanation'] = self.explanation 
    end
    result
  end

  def self.get_or_make(statement, statement_type)
    user = current_user
    
    your_opinion = statement.opinions.where(:user_id => user.id).order('id DESC')

    if your_opinion.length > 1
      pp "Duplicate opinions for user #{user}: #{your_opinion.map {|o| o.id} }!"
    end
    
    your_opinion = your_opinion.first


    # Otherwise create one
    if your_opinion.nil?
      ActsAsTenant.without_tenant do 
        your_opinion = Opinion.create!(:statement_id => statement.id,
                                      :statement_type => statement_type,
                                      :user => user,
                                      :subdomain_id => statement.subdomain_id,
                                      :stance => 0,
                                      :published => true,
                                      :point_inclusions => []
                                     )
      end 
    end
    your_opinion
  end

  def key
    "/opinion/#{self.id}"
  end

  def publish(previously_published = false)
    return if self.published

    self.published = true
    recache
    self.save if changed?

    if self.statement_type == 'Proposal'
      # New opinion means the proposal needs to be re-fetched so that
      # it includes it in its list of stuff
      dirty_key "/page/#{self.statement.slug}"

      # Need to recache the included points so that the user is shown as an official
      # includer of this point now that the opinion is being published. 
      inclusions.each do |inc|
        inc.point.recache
      end

    end

    if !previously_published
      Notifier.notify_parties 'new', self
    end

    current_user.update_subscription_key(statement.key, 'watched', :force => false)

    dirty_key "/current_user"

  end

  def unpublish
    self.published = false
    recache
    self.save if changed?

    if self.statement_type != 'Proposal'
      raise "migrate!"
    end 

    inclusions.each do |inc|
      inc.point.recache
    end

    if self.statement_type == "Proposal"
      dirty_key "/page/#{self.statement.slug}"
    end
    dirty_key self.statement.key 
  end

  def update_inclusions (points_to_include)
    pp "\n migrate opinion.update_inclusions!\n"


    points_already_included = inclusions.map {|i| i.point_id}.compact
    points_to_exclude = points_already_included.select {|point_id| not points_to_include.include? point_id}
    points_to_add    = points_to_include.select {|p_id| not points_already_included.include? p_id }

    # puts("Excluding points #{points_to_exclude}, including points #{points_to_add}")

    # Delete goners
    points_to_exclude.each do |point_id|
      self.exclude point_id
    end
    
    # Add newbies
    points_to_add.each do |point_id|
      self.include point_id
    end

  end

  def include(point, subdomain = nil)
    pp "\nmigrate opinion.include!\n"

    subdomain ||= current_subdomain
    if not point.is_a? Point
      point = Point.find point
    end

    user = User.find(self.user_id)

    if !point.id
      Rails.logger.error "TRYING TO INCLUDE A POINT THAT DOESN'T EXIST"
      return
    end    
    
    if user.inclusions.where( :point_id => point.id ).count > 0
      point.recache 
      self.recache
      Rails.logger.error "Including a point (#{point.id}) for user #{self.user_id} twice!'"
      return
    end

    attrs = { 
      :point_id => point.id,
      :user_id => self.user_id,
      :proposal_id => self.proposal_id,
      :subdomain_id => subdomain.id
    }
    Inclusion.create! attrs

    point.recache
    self.recache

    dirty_key("/point/#{point.id}")
    dirty_key("/opinion/#{self.id}")
  end

  def exclude(point)
    pp "\nmigrate opinion.exclude!\n"

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

  def recache
    pp "\nmigrate opinion.recache!\n"
    self.point_inclusions = inclusions.select(:point_id).map {|x| x.point_id }.uniq.compact
    self.save
  end

  def inclusions
    pp "\nmigrate inclusions!\n"
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
        next if ops.count < 2
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

  end

end



