

class Users::SessionsController < Devise::SessionsController
	protect_from_forgery :except => :create

  def new     
    store_location request.referer
    if ( params[:third_party] )
    	case params[:provider]
	    	when 'twitter'
	    		redirect_to user_omniauth_authorize_path(:twitter).to_s
	    	when 'facebook'
	    		redirect_to user_omniauth_authorize_path(:facebook).to_s
	    	when 'google'
	    		redirect_to user_omniauth_authorize_path(:google).to_s
	    	when 'yahoo'
	    		redirect_to user_omniauth_authorize_path(:yahoo, :openid_url => "http://yahoo.com").to_s
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

    if current_user && session.has_key?(:domain) && session[:domain] && session[:domain] != current_user.domain_id
      current_user.domain_id = session[:domain]
      current_user.save
    elsif current_user && current_user.domain_id
      session[:domain] = current_user.domain_id
    end

    respond_with resource, :location => redirect_location(resource_name, resource)
  end


end

