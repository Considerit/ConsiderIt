class HomeController < ApplicationController
  #caches_page :index
  respond_to :json, :html

  def index
    @user = current_user
  end

  def show
    render :action => params[:page]
  end  

  def set_domain
    domain = Domain.where(:identifier => params[:domain]).first()
    if domain
      session[:domain] = domain
      if current_user
        current_user.domain_id = session[:domain]
        current_user.save
      end
    end
    
    redirect_to request.referrer
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
