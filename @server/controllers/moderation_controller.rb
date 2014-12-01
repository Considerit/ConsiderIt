class ModerationController < ApplicationController

  rescue_from CanCan::AccessDenied do |exception|
    result = {
      :errors => [current_user.nil? ? 'not logged in' : 'not authorized']
    }
    render :json => result 
    return
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
        :current_subdomain => current_subdomain
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
  if model.moderation
    model.moderation.updated_since_last_evaluation = true
    model.moderation.save
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
