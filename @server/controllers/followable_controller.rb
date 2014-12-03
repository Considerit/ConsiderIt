class FollowableController < ApplicationController
  def index
    follows = current_user.notifications
    render :json => [{:key => '/dashboard/email_notifications', :follows => follows}]
  end  
end