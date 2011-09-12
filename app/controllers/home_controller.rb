require 'ruby-debug'
class HomeController < ApplicationController
  #caches_page :index
  
  def index
    @user = current_user
  end

  def show
    render :action => params[:page]
  end  

  def set_zipcode
    session[:zip] = params[:zip]
    if current_user
      current_user.zip = params[:zip]
      current_user.save
    end

    #TODO: check to make sure zip is valid
    respond_to do |format|
      format.js {render :partial => "home/zip_set", :locals => { :zip => params[:zip] }}
    end
  end

  def take_pledge
    current_user.pledge_taken = true
    current_user.save
    
    @third_party_account = current_user.facebook_uid || current_user.twitter_uid || current_user.yahoo_uid || current_user.google_uid
    if @third_party_account
      flash[:notice] = "Welcome to the LVG community!"
    end

    respond_to do |format|
      format.js {render :partial => "users/sessions/confirmation_sent"}
    end
        
  end

end
