class HomeController < ApplicationController
  #caches_page :index
  respond_to :json, :html

  def index
    redirect_to Option.find(1)

    @user = current_user
    @keywords = "Washington Voters Guide 2011 Election Ballot Measures Initiatives"
    @description = "A guide to the Washington State 2011 election, written by citizens like you. Think through the pros and cons of state and local ballot measures and initiatives. Discover what other voters think."
  end

  def show
    render :action => params[:page]
  end  

  def set_domain
    domain = Domain.where(:identifier => params[:domain]).first()
    if domain
      session[:domain] = domain.id
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

    response = {:html => render_to_string(:partial => "users/sessions/confirmation_sent")}
    render :json => response.to_json

  end

  def study
    category = params[:category]
    sd = StudyData.create!({
      :category => category.to_i,
      :user_id => current_user ? current_user.id : nil,
      :session_id => request.session_options[:id],

      :position_id => params[:position_id],
      :point_id => params[:point_id],
      :option_id => params[:option_id],
      :detail1 => params[:detail1],
      :detail2 => params[:detail2],
      :ival => params[:ival].to_i,
      :fval => params[:fval].to_f,
      :bval => params[:bval] == 'true'
    })
    response = {:success => "success"}
    render :json => response.to_json

  end

end
