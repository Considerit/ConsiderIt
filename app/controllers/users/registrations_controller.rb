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

      clean_up_passwords(user)
      sign_in(resource_name, user)
      if session.has_key?('position_to_be_published')
        session['reify_activities'] = true 
      end    

      if current_user && session.has_key?(:domain) && session[:domain] && session[:domain] != current_user.domain_id
        current_user.domain_id = session[:domain]
        current_user.save
      elsif current_user && current_user.domain_id
        session[:domain] = current_user.domain_id
      end

      #respond_with user, :location => session[:return_to] || redirect_location(resource_name, user)
      redirect_to request.referer
      
    else #otherwise create new user...
      resource = build_resource
      if resource.save
        if resource.active_for_authentication?
          sign_in(resource_name, resource)
          if current_user && session[:domain] != current_user.domain_id
            current_user.domain_id = session[:domain]
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
    current_user.update_attributes(params[:user])
    current_user.save
    redirect_to request.referer
  end

  def check_login_info    
    email = params[:user][:email]
    password = params[:user][:password]

    user = User.find_by_email(email)
    email_in_use = !user.nil?

    render :json => { :valid => !email_in_use || user.valid_password?(password) }
  end

end