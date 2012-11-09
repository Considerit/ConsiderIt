#*********************************************
# For the ConsiderIt project.
# Copyright (C) 2010 - 2012 by Travis Kriplean.
# Licensed under the AGPL for non-commercial use.
# See https://github.com/tkriplean/ConsiderIt/ for details.
#*********************************************

class Users::RegistrationsController < Devise::RegistrationsController
	protect_from_forgery :except => :create

  def new
    @context = params[:context]    
    super
  end

  def create
    
    #if the user already exists...(equiv of user/sign_in)
    user = User.find_by_email(params[:user][:email])
    if user
      if user.valid_password?(params[:user][:password])
        #clean_up_passwords(user)
        sign_in(resource_name, user)
        if session.has_key?('position_to_be_published')
          session['reify_activities'] = true 
        end    

        if current_user && session.has_key?(:domain) && session[:domain] && !current_user.tags.include?(session[:domain])
          current_user.tags = params[:domain] 
          current_user.save
        elsif current_user && current_user.tags
          session[:domain] = current_user.tags
        end

        #respond_with user, :location => session[:return_to] || redirect_location(resource_name, user)
        redirect_to request.referer
      else
        redirect_to root_path, :notice => 'Incorrect password'
      end
    else #otherwise create new user...
      resource = build_resource
      resource.referer = session[:referer] if session.has_key?(:referer)
      if resource.save
        if resource.active_for_authentication?
          sign_in(resource_name, resource)
          current_user.track!

          if current_user && session.has_key?(:domain) && session[:domain] && !current_user.tags.include?(session[:domain])
            current_user.tags = params[:domain] 
            current_user.save
          end

          if session.has_key?('position_to_be_published')
            session['reify_activities'] = true 
          end
          set_flash_message :notice, :signed_up
          redirect_to request.referer
        else
          set_flash_message :notice, :"signed_up_but_#{resource.inactive_message}" if is_navigational_format?
          expire_session_data_after_sign_in!
          respond_with resource, :location => after_inactive_sign_up_path_for(resource)
        end
      else
        clean_up_passwords resource
        respond_with resource
      end

    end
    
  end

  def update
    # not using skip confirmation because it sets confirmed_at on additional info provisioning...not sure why it was enabled
    #current_user.skip_confirmation!
    current_user.update_attributes(params[:user])
    #current_user.skip_confirmation!
    current_user.save

    if params[:user].has_key?(:proposal_id)
      # this is for caching purposes, particularly the histogram
      Proposal.find_by_id(params[:user].delete(:proposal_id)).touch
    end
    redirect_to !request.referer.nil? ? request.referer : root_path
  end

  def check_login_info    
    email = params[:user][:email]
    password = params[:user][:password]

    user = User.find_by_email(email)
    email_in_use = !user.nil?

    render :json => { :valid => !email_in_use || user.valid_password?(password) }
  end

end