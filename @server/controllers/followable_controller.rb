class FollowableController < CurrentUserController
  def index
    target_user = user()

    authorized = target_user && target_user.id == current_user.id

    # TODO: This is a SUPER BAD idea to allow permanent access to an account via a login token. 
    #       Need to change this. Options: 
    #          - Make all unsubscription requests from the notifications dash come through this controller
    #          - Make the token valid only for a day or two
    if !authorized && target_user && is_valid_token(target_user)
      authorized = true
      replace_user(current_user, target_user)
      set_current_user(target_user)
      dirty_key('/current_user')
    end

    if authorized
      follows = current_user.notifications
      render :json => [{:key => '/dashboard/email_notifications', :follows => follows}]
    else
      render :json => {:success => false, :reason => "Permission denied"}
    end
  end

  private

  def user
    return current_user if current_user.registration_complete
    return false if !session[:notifications_user]
    u = session[:notifications_user]['u']
    return User.find_by_email(u)
  end

  def is_valid_token(target_user)
    u = session[:notifications_user]['u']
    t = session[:notifications_user]['t']

    encrypted = ApplicationController.arbitrary_token("#{u}#{target_user.unique_token}#{current_tenant.identifier}")
    
    encrypted == t
  end
  
end