class Opinion < ActiveRecord::Base
  belongs_to :user
  belongs_to :proposal, :touch => true 
  has_many :inclusions
  has_many :points
  has_many :point_listings
  has_many :comments, :as => :commentable, :dependent => :destroy
  
  # has_paper_trail

  include Followable, Commentable

  acts_as_tenant(:account)

  scope :published, -> {where( :published => true )}
  scope :public_fields, -> {select( [:long_id, :created_at, :updated_at, :id, :proposal_id, :stance, :stance_segment, :user_id, :explanation, :point_inclusions, :published] )}

  before_save do 
    self.explanation = self.explanation.sanitize if self.explanation
    self.stance_segment = Opinion.get_segment(self.stance)
  end 

  def as_json(options={})
    pubs = ['long_id', 'created_at', 'updated_at', 'id', 'point_inclusions',
            'proposal_id', 'stance', 'stance_segment', 'user_id', 'explanation',
            'published']

    result = super(options)
    result = result.select{|k,v| pubs.include? k}

    make_key(result, 'opinion')
    stubify_field(result, 'user')
    stubify_field(result, 'proposal')
    result['point_inclusions'] = JSON.parse (result['point_inclusions'] || '[]')
    result['point_inclusions'].map! {|p| "/point/#{p}"}
    result.delete('long_id')
    result
  end

  def self.get_or_make(proposal, user)
    # Each (user,proposal) should have only one opinion.

    if not user
      raise "Need a user to get their opinion!"
    end
    
    # First try to find a published opinion for this user
    your_opinion = Opinion.where(:proposal_id => proposal.id, 
                                 :user => user)
    if your_opinion.length > 1
      raise "Duplicate opinions for user #{user}: #{your_opinion.map {|o| o.id} }!"
    end
    your_opinion = your_opinion.first

    # Otherwise create one
    if not your_opinion
      your_opinion = Opinion.create(:proposal_id => proposal.id,
                                    :user => user ? user : nil,
                                    :long_id => proposal.long_id,
                                    :account_id => Thread.current[:tenant].id,
                                    :published => false,
                                    :stance => 0,
                                    :point_inclusions => '[]',
                                    :explanation => ''
                                   )
    end
    your_opinion
  end
    
  def include(point)
    point_id = (point.is_a?(Point) && point.id) || point
    dirty_key("/point/#{point_id}")
    dirty_key("/opinion/#{self.id}")

    if Inclusion.where( :point_id => point_id, :user_id => self.user_id ).count !=0
      raise 'Including a point twice!'
    end
    
    attrs = { 
      :point_id => point_id,
      :user_id => self.user_id,
      :opinion_id => self.id,
      :proposal_id => self.proposal_id,
      :account_id => Thread.current[:tenant].id
    }
          
    Inclusion.create! ActionController::Parameters.new(attrs).permit!
    self.recache()
  end    
  
  def absorb( opinion )
    puts("Absorbing opinion #{opinion.id} into #{self.id}")

    # First record everything we're dirtying and remapping
    dirty_key("/opinion/#{id}")
    remap_key("/opinion/#{opinion.id}", "/opinion/#{id}")
    points = opinion.points
    points.each {|p| dirty_key("/point/#{p.id}")}

    # Change the absorbed's everythings to point at this opinion
    opinion.point_listings.update_all({:user_id => user_id, :opinion_id => id})
    opinion.points.update_all(        {:user_id => user_id, :opinion_id => id}) # We don't use this field anymore
    opinion.comments.update_all(      {:commentable_id => id})
    self.published = self.published or opinion.published

    # Union the included points
    included_points_union = (     self.inclusions.map{|i| i.point.id} \
                             + opinion.inclusions.map{|i| i.point.id}).uniq
    self.include_points(included_points_union) # And this will recache

    opinion.destroy()
  end

  def change_user(new_user)
    puts("Changing user for #{opinion.id} to #{new_user}")

    # First record everything we're dirtying and remapping
    dirty_key("/opinion/#{id}")
    self.points.each {|p| dirty_key("/point/#{p.id}")}

    # Change the opinion's everythings to point at the new user
    self.point_listings.update_all({:user_id => user_id})
    self.points.update_all(        {:user_id => user_id}) # We should remove opinion.points
    self.inclusions.update_all(    {:user_id => user_id}) # We should remove inclusions.user_id field
    self.recache()                                        # We don't use either of those fields anymore

    # Update each point.includers field
    self.points.each {|p| p.update_absolute_score}

    opinion.destroy()
  end    

  def recache
    inclusions = self.inclusions.select(:point_id)
    self.point_inclusions = inclusions.map {|x| x.point_id }.uniq.compact.to_s
    self.save
  end

  def self.get_segment(value)
    if value == -1
      return 0
    elsif value == 1
      return 6
    elsif value <= 0.05 && value >= -0.05
      return 3
    elsif value >= 0.5
      return 5
    elsif value <= -0.5
      return 1
    elsif value >= 0.05
      return 4
    elsif value <= -0.05
      return 2
    end   
  end

  def stance_name
    case stance_segment
      when 0
        return "strong oppose"
      when 1
        return "oppose"
      when 2
        return "weak oppose"
      when 3
        return "undecided"
      when 4
        return "weak support"
      when 5
        return "support"
      when 6
        return "strong support"
    end
  end

  def stance_name_singular
    case stance_segment
      when 0
        return "strongly opposes"
      when 1
        return "opposes"
      when 2
        return "weakly opposes"
      when 3
        return "is neutral about"
      when 4
        return "weakly supports"
      when 5
        return "supports"
      when 6
        return "strongly supports"
    end
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
      p.update_absolute_score(true)
    end
    'done'
  end

  def self.purge
    Opinion.where('user_id IS NULL').destroy_all
    
    User.find_each do |u|
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



