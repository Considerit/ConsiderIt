#*********************************************
# For the ConsiderIt project.
# Copyright (C) 2010 - 2012 by Travis Kriplean.
# Licensed under the AGPL for non-commercial use.
# See https://github.com/tkriplean/ConsiderIt/ for details.
#*********************************************


class Users::SessionsController < Devise::SessionsController
	protect_from_forgery :except => :create

  def new     
    store_location request.referer
    if ( params[:third_party] )
    	case params[:provider]
	    	when 'twitter'
	    		redirect_to user_omniauth_authorize_path(:twitter, :x_auth_access_type => "read").to_s
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

end

