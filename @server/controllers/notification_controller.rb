class NotificationController < ApplicationController
  def index
    render :json => [{:key => '/dashboard/email_notifications', :follows => current_user.notifications}]
  end  
end