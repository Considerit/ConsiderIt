class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController

  def facebook
    _third_party_callback
  end

  def google
    _third_party_callback
  end

  def google_oauth2
    _third_party_callback
  end

  def twitter
    _third_party_callback
  end

  protected

  def _third_party_callback
    access_token = env["omniauth.auth"]
    user = User.find_by_third_party_token access_token

    if user && user.registration_complete
      sign_in user, :event => :authentication
      params = { :user => user, :follows => user.follows.to_a, :new_csrf => form_authenticity_token } #TODO: filter this down (actually, it might not be needed)
    else
      session[:access_token] = access_token
      user = User.create_from_third_party_token(access_token)
      params = { :user => {:user => user, :follows => [], :new_csrf => form_authenticity_token } }
    end

    render :inline =>
      "<script type=\"text/javascript\">" +
      "  window.open_id_params = #{params.to_json};  " + 
      "</script>"

  end
 

end
