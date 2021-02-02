class ModerationController < ApplicationController

  def show 
    authorize! 'moderate content'
    dirty_key "/moderation/#{params[:id]}"
    render :json => []
  end

  def update
    authorize! 'moderate content'

    moderation = Moderation.find params[:id] 

    updates = {
      'status' => params['status'],
      'user_id' => current_user.id,
      'updated_since_last_evaluation' => false
    }

    moderation.update_attributes! updates
    
    moderatable = moderation.root_object
    if moderatable.moderation_status != moderation.status
      moderatable.moderation_status = moderation.status
      moderatable.save

      if moderatable.moderation_status == 1 && [1,2].include?(current_subdomain.moderation_policy)
        Notifier.notify_parties 'new', moderatable
      end
    end

    if moderation.moderatable_type.downcase == 'proposal'
      dirty_key '/proposals'
    end

    dirty_key "/#{moderation.moderatable_type.downcase}/#{moderatable.id}"
    dirty_key "/moderation/#{moderation.id}"

    render :json => []
  end

end