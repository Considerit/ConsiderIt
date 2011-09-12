

class Users::SessionsController < Devise::SessionsController
	protect_from_forgery :except => :create

  def new     
    store_location request.referer
    if ( params[:third_party] )
    	case params[:provider]
	    	when 'twitter'
	    		redirect_to user_omniauth_authorize_path(:twitter)
	    	when 'facebook'
	    		redirect_to user_omniauth_authorize_path(:facebook)
	    	when 'google'
	    		redirect_to user_omniauth_authorize_path(:google)
	    	when 'yahoo'
	    		redirect_to user_omniauth_authorize_path(:yahoo, :openid_url => "http://yahoo.com")
	    	else
	    		raise 'Unsupported provider'
    	end
    	return
    end
    super
  end

  # POST /resource/sign_in
  def create
    resource = warden.authenticate!(:scope => resource_name, :recall => "#{controller_path}#new")
    #set_flash_message(:notice, :signed_in) if is_navigational_format?
    sign_in(resource_name, resource)
    if session.has_key?('position_to_be_published')
      session['reify_activities'] = true 
    end    

    if current_user && session[:zip] != current_user.zip
      current_user.zip = session[:zip]
      current_user.save
    end

    respond_with resource, :location => redirect_location(resource_name, resource)
  end


end

