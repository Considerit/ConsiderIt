class NotificationController < ApplicationController

  def index  
    proposal = Proposal.find params[:proposal_id]
    authorize! 'read proposal', proposal
    
    render :json => [{
      key: "/notifications/#{proposal.id}",
      notifications: proposal.safe_notifications
    }]
  end 

  def update
    notification = Notification.find key_id(params[:key])

    if params['read_at']

      notification.read_at = Time.now()
      notification.save

      dirty_key '/current_user'
    end

    render :json => []

  end

end