class DeveloperController < ApplicationController  
  respond_to :html

  def change_subdomain

    if Rails.env.development? || request.host.end_with?('chlk.it')
      session[:default_subdomain] = params['id']
    end

    redirect_to '/'
  end

  def set_app
    if Rails.env.development? || request.host.end_with?('chlk.it')
      session[:app] = params['app']
    end

    redirect_to '/'
  end
end