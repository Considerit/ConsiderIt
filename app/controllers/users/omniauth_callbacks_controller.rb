#*********************************************
# For the ConsiderIt project.
# Copyright (C) 2010 - 2012 by Travis Kriplean.
# Licensed under the AGPL for non-commercial use.
# See https://github.com/tkriplean/ConsiderIt/ for details.
#*********************************************

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
    
  def facebook
    _third_party_callback
  end

  def google
    _third_party_callback
  end

  def twitter
    _third_party_callback
  end

  def yahoo
    _third_party_callback
  end

  protected

  def _third_party_callback

    @user = User.find_for_third_party_auth(env["omniauth.auth"], current_user)
    @user.referer = session[:referer] if session.has_key?(:referer)
    @user.save
    
    if @user.persisted?
      @user.skip_confirmation!
      sign_in @user, :event => :authentication
      if session.has_key?('position_to_be_published')
        session['reify_activities'] = true 
      end

      if @user && session.has_key?(:domain) && session[:domain] && !@user.tags.include?(session[:domain])
        @user.tags = params[:domain] 
        @user.save
      elsif @user && @user.tags
        session[:domain] = current_user.tags
      end

    else
      session["devise.third_party"] = env["omniauth.auth"]
      #redirect_to new_user_registration_url
    end

    @redirect_to = session[:return_to] || root_path
    render :inline =>
      '<script type="text/javascript">' +
      '  window.close();' +
      '  window.opener.location = "<%= @redirect_to %>";' +
      '</script>'

  end
 

end
