#*********************************************
# For the ConsiderIt project.
# Copyright (C) 2010 - 2012 by Travis Kriplean.
# Licensed under the AGPL for non-commercial use.
# See https://github.com/tkriplean/ConsiderIt/ for details.
#*********************************************

class HomeController < ApplicationController
  #caches_page :index
  respond_to :json, :html

  caches_action :index, :cache_path => proc {|c|
    updated_at = current_tenant.proposals.count > 0 ? current_tenant.proposals.order('updated_at DESC').limit(1).first.updated_at.to_i : 0
    {:tag => "is_logged_in-#{current_user ? "#{current_user.id}-#{current_user.registration_complete}-#{current_user.avatar_file_name}"  : '-1'}-#{updated_at}-#{session.has_key?(:domain) ? session[:domain] : -1}"}
  }

  def index
    # TODO: move this to config somehow
    if current_tenant.app_title == 'Living Voters Guide'
      @title = "2012 #{current_tenant.identifier == 'cali' ? 'California' : 'Washington'} Election"
      @keywords = "voters guide 2012 ballot #{current_tenant.identifier == 'cali' ? 'california san francisco los angeles san diego riverside irvine sacramento' : 'washington state wa seattle tacoma spokane yakima vancouver'} election pamphlet ballot measures propositions"
      @description = "#{current_tenant.identifier == 'cali' ? 'California\'s' : 'Washington\'s'} citizen-powered voters guide. Engage with your virtual neighbors about the 2012 election. Experience a better democracy."
    elsif current_tenant.app_title == 'Office of Hawaiian Affairs'
      @title = "Educate. Deliberate. Advocate."
      @keywords = "Educate, Deliberate, Advocate, hawaii, office of hawaiian affairs, oha"
      @description = "Help us think through the issues we are considering"
    else
      @title = current_tenant.app_title
      @keywords = "#{current_tenant.app_title} deliberate decide"
      @description = "Discuss issues at #{current_tenant.app_title}"
    end
  end

  def show
    render :action => params[:page]
  end  

  def set_domain
    
    session[:domain] = params[:domain]
    if current_user
      current_user.tags = params[:domain]
      current_user.save
    end
    
    redirect_to request.referrer
  end

  def study
    category = params[:category]
    sd = StudyData.create!({
      :category => category.to_i,
      :user_id => current_user ? current_user.id : nil,
      :session_id => request.session_options[:id],

      :position_id => params[:position_id],
      :point_id => params[:point_id],
      :proposal_id => params[:proposal_id],
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
