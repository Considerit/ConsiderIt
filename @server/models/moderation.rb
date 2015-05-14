class Moderation < ActiveRecord::Base

  class_attribute :STATUSES
  self.STATUSES = %w(fails passes)

  belongs_to :moderatable, :polymorphic=>true
  belongs_to :user
  
  acts_as_tenant :subdomain

  class_attribute :my_public_fields
  self.my_public_fields = [:user_id, :id, :status, :moderatable_id, :moderatable_type, :updated_at, :updated_since_last_evaluation]

  def self.all_for_subdomain

    moderations = []

    current_subdomain.classes_to_moderate.each do |moderation_class|

      if moderation_class == Comment
        # select all comments of points of active proposals
        qry = "SELECT c.id, c.user_id, prop.id as proposal_id FROM comments c, points pnt, proposals prop WHERE prop.subdomain_id=#{current_subdomain.id} AND prop.active=1 AND prop.id=pnt.proposal_id AND c.point_id=pnt.id"
      elsif moderation_class == Point
        qry = "SELECT pnt.id, pnt.user_id, pnt.proposal_id FROM points pnt, proposals prop WHERE prop.subdomain_id=#{current_subdomain.id} AND prop.active=1 AND prop.id=pnt.proposal_id AND pnt.published=1"
      elsif moderation_class == Proposal
        qry = "SELECT id, slug, user_id, name, description from proposals where subdomain_id=#{current_subdomain.id}"
      end

      objects = ActiveRecord::Base.connection.exec_query(qry)

      if objects.count > 0

        existing_moderations = Moderation.where("moderatable_type='#{moderation_class.name}' AND moderatable_id in (?)", objects.map {|o| o['id']})
        if existing_moderations.count > 0
          existing_moderations = Hash[existing_moderations.collect { |v| [v.moderatable_id, v] }]
        else 
          existing_moderations = {}
        end


        objects.each do |obj|
          dirty_key "/#{moderation_class.name.downcase}/#{obj['id']}"
          if obj.has_key? 'proposal_id'
            dirty_key "/proposal/#{obj['proposal_id']}"
          end

          dirty_key "/user/#{obj['user_id']}"

          if existing_moderations.has_key? obj['id']
            moderation = existing_moderations[obj['id']]
          else 
            # Create a moderation for each that doesn't yet exist.           
            moderation = Moderation.create! :moderatable_type => moderation_class.name, :moderatable_id => obj['id'], :subdomain_id => current_subdomain.id
          end

          moderations.push moderation
        end
      end

    end
    
    {
      key: '/page/dashboard/moderate',
      moderations: moderations
    }

  end

  def root_object
    moderatable_type.constantize.find(moderatable_id)
  end

  def as_json(options={})
    options[:only] ||= Moderation.my_public_fields
    result = super(options)

    result['moderatable'] = "/#{moderatable_type.downcase}/#{moderatable_id}"
    make_key result, 'moderation'  
    stubify_field result, 'user'
    result

  end

end
