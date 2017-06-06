class DeveloperController < ApplicationController  
  respond_to :html

  def change_subdomain

    if Rails.env.development? || request.host.end_with?('chlk.it')
      session[:default_subdomain] = params['id']
    end

    redirect_to '/'
  end

end