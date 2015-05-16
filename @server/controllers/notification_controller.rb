class NotificationController < ApplicationController

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