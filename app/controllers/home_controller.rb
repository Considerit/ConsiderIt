class HomeController < ApplicationController
  #caches_page :index
  respond_to :json, :html

  caches_action :index, :cache_path => proc {|c|
    updated_at = current_tenant.proposals.count > 0 ? current_tenant.proposals.order('updated_at DESC').limit(1).first.updated_at.to_i : 0
    {:tag => "is_logged_in-#{current_user ? "#{current_user.id}-#{current_user.registration_complete}-#{current_user.avatar_file_name}"  : '-1'}-#{updated_at}-#{current_tenant.updated_at}-#{session.has_key?(:domain) ? session[:domain] : -1}"}
  }

  def render(*args)
    @current_page = 'homepage'
    super
  end

  def index
    # TODO: move this to config somehow
    # if current_tenant.theme == 'lvg'
    #   @title = "Living Voters Guide: 2013 #{current_tenant.identifier == 'cali' ? 'California' : 'Washington'} Election"
    #   @keywords = "voters guide 2012 ballot #{current_tenant.identifier == 'cali' ? 'california san francisco los angeles san diego riverside irvine sacramento' : 'washington state wa seattle tacoma spokane yakima vancouver'} election pamphlet ballot measures propositions"
    #   @description = "#{current_tenant.identifier == 'cali' ? 'California\'s' : 'Washington\'s'} citizen-powered voters guide. Engage with your virtual neighbors about the 2012 election. Experience a better democracy."
    # elsif current_tenant.theme == 'directrep'
    #   theme = Themes::ThemeDirectrep.find_by_account_id(current_tenant.id)
    #   @title = "DirectRep #{theme.rep_name.split(' ')[-1]}"
    #   @keywords = "Listening Dialogue Citizen Government Representative Democracy Communication Deliberation"
    #   @description = "Representative #{theme.rep_name} wants your help thinking through the issues being considered."
    # elsif current_tenant.theme == 'policyninja'
    #   @title = "Educate. Deliberate. Advocate. Office of Hawaiian Affairs"
    #   @keywords = "Educate, Deliberate, Advocate, hawaii, office of hawaiian affairs, oha"
    #   @description = "Help us think through the issues we are considering"
    # else
    @title = current_tenant.app_title
    @keywords = "#{current_tenant.app_title} deliberate decide"
    @description = "ConsiderIt: Discuss issues at #{current_tenant.app_title}"

  end

  def show
    if params[:page] == 'help'
      redirect_to root_path
    else
      render :action => params[:page]
    end
  end  

  def set_domain
    
    session[:domain] = params[:domain]
    if current_user
      current_user.save
    end
    
    redirect_to request.referrer
  end

  def avatars
    
  end
  
  def content_for_user
    # proposals that are written by this user, but not yet published; private proposals this user has access to
    proposals = []
    Proposal.content_for_user(current_user).each do |proposal|      
      proposals.push ({
        :model => proposal,
        :top_con => proposal.top_con ? Point.where('id=(?)', proposal.top_con).public_fields.first : nil,
        :top_pro => proposal.top_pro ? Point.where('id=(?)', proposal.top_pro).public_fields.first : nil,
      }) 
    end

    render :json => {
      :points => current_user.points.published.where(:hide_name => true).joins(:proposal).select('proposals.long_id, points.id, points.is_pro'),
      :proposals => proposals
    }
  end

  def set_dev_options
    session["user_theme"] = params[:theme]
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
