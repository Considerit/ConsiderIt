class NotificationController < ApplicationController

  def update

    notification = Notification.find params[:id] 

    updates = {
      'read_at' => params['read_at']
    }

    notification.update_attributes! updates

    dirty_key '/current_user'

    render :json => []

  end

end