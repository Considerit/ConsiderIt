class ModerationController < ApplicationController

  rescue_from CanCan::AccessDenied do |exception|
    result = {
      :errors => [current_user.nil? ? 'not logged in' : 'not authorized']
    }
    render :json => result 
    return
  end

  # list all the objects to be moderated; allow seeing the existing moderations
  def index
    authorize! :index, Moderation

    moderations = []

    current_tenant.classes_to_moderate.each do |moderation_class|

      if moderation_class == Comment
        # select all comments of points of active proposals
        qry = "SELECT c.id, c.user_id, prop.id as proposal_id FROM comments c, points pnt, proposals prop WHERE prop.account_id=#{current_tenant.id} AND prop.active=1 AND prop.id=pnt.proposal_id AND c.point_id=pnt.id"
      elsif moderation_class == Point
        qry = "SELECT pnt.id, pnt.user_id, pnt.proposal_id FROM points pnt, proposals prop WHERE prop.account_id=#{current_tenant.id} AND prop.active=1 AND prop.id=pnt.proposal_id AND pnt.published=1"
      elsif moderation_class == Proposal
        qry = "SELECT id, long_id, user_id, name, description from proposals where account_id=#{current_tenant.id}"
      end

      objects = ActiveRecord::Base.connection.select(qry)

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
            moderation = Moderation.create! :moderatable_type => moderation_class.name, :moderatable_id => obj['id'], :account_id => current_tenant.id
          end

          moderations.push moderation
        end
      end

    end
    result = {
      key: '/dashboard/moderate',
      moderations: moderations
    }
    render :json => [result]

  end

  def update
    authorize! :update, Moderation

    moderation = Moderation.find params[:id] 

    updates = {
      'status' => params['status'],
      'user_id' => current_user.id,
      'updated_since_last_evaluation' => false
    }

    moderation.update_attributes! updates
    
    if !moderation.notification_sent && moderation.status == 1
      ActiveSupport::Notifications.instrument("moderation:#{moderation.moderatable_type.downcase}:passed", 
        :model => moderation.root_object,
        :current_tenant => current_tenant,
        :mail_options => mail_options
      )      

      moderation.notification_sent = true
      moderation.save
    end

    moderatable = moderation.root_object
    moderatable.moderation_status = moderation.status
    moderatable.save

    dirty_key "/#{moderation.moderatable_type.downcase}/#{moderatable.id}"
    dirty_key "/moderation/#{moderation.id}"

    render :json => []
  end

end


def handle_moderatable_model_update(model)
  model.moderations.each do |mod|
    mod.updated_since_last_evaluation = true
    mod.save
  end
end

ActiveSupport::Notifications.subscribe("proposal:updated") do |*args|
  handle_moderatable_model_update args.last[:model]
end

ActiveSupport::Notifications.subscribe("point:updated") do |*args|
  handle_moderatable_model_update args.last[:model]
end

ActiveSupport::Notifications.subscribe("comment:updated") do |*args|
  handle_moderatable_model_update args.last[:model]
end
