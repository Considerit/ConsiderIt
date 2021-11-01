class Opinion < ApplicationRecord
  belongs_to :user
  belongs_to :statement, :polymorphic => true, :touch => true
  
  include Notifier

  acts_as_tenant :subdomain

  scope :published, -> {where( :published => true )}
  scope :public_fields, -> {select( [:created_at, :updated_at, :id, :statement_id, :statement_type, :stance, :user_id, :published, :subdomain_id] )}


  def as_json(options={})
    pubs = ['created_at', 'updated_at', 'id',
            'stance', 'user_id', 'published']

    result = super(options)
    result = result.select{|k,v| pubs.include? k}

    make_key(result, 'opinion')
    stubify_field(result, 'user')
    result['statement'] = "/#{self.statement_type.downcase}/#{self.statement_id}"

    if self.explanation
      result['explanation'] = self.explanation 
    end
    result
  end

  def key
    "/opinion/#{self.id}"
  end

  def publish(previously_published = false)
    return if self.published

    self.published = true
    self.save if changed?

    if self.statement_type == 'Proposal'
      # New opinion means the proposal needs to be re-fetched so that
      # it includes it in its list of stuff
      dirty_key "/page/#{self.statement.slug}"
    end

    if !previously_published
      Notifier.notify_parties 'new', self
    end

    current_user.update_subscription_key(statement.key, 'watched', :force => false)

    dirty_key "/current_user"

  end

  def unpublish
    self.published = false
    self.save if changed?

    if self.statement_type != 'Proposal'
      raise "migrate!"
    end 

    if self.statement_type == "Proposal"
      dirty_key "/page/#{self.statement.slug}"
    end
    dirty_key self.statement.key 
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



