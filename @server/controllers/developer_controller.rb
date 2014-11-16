class DeveloperController < ApplicationController  
  respond_to :html

  def change_default_customer

    if Rails.env.development?
      session[:default_customer] = params['id']
    end


    redirect_to :back

  end
end