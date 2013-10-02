class HomeController < ApplicationController
  #caches_page :index
  respond_to :json, :html

  caches_action :avatars, :cache_path => proc {|c|
    {:tag => "avatars-#{current_tenant.id}-#{Rails.cache.read("avatar-digest-#{current_tenant.id}")}"}
  }

  # def render(*args)
  #   @current_page = 'homepage'
  #   super
  # end

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

  def avatars
    #result = render_to_string :partial => 'home/avatars'
    render :partial => 'home/avatars'
  end

  def content_for_user
    # proposals that are written by this user; private proposals this user has access to
    proposals = Proposal.content_for_user(current_user)

    top = proposals.where('top_con IS NOT NULL').select(:top_con).map {|x| x.top_con}.compact +
          proposals.where('top_pro IS NOT NULL').select(:top_pro).map {|x| x.top_pro}.compact 
    top_points = {}
    Point.where('id in (?)', top).public_fields.each do |pnt|
      top_points[pnt.id] = pnt
    end

    current_user.points.published.where(:hide_name => true).public_fields.each do |pnt|
      top_points[pnt.id] = pnt
    end

    render :json => {
      :top_points => top_points.values,
      :proposals => proposals.public_fields
    }
  end

  # right now this is only used by LVG for zip codes...
  def set_tag

    new_tags = params[:tags].split(';')

    if current_user
      current_user.addTags new_tags, params['overwrite_type']
      tags = current_user.getTags()
    else
      tags = session.has_key?(:tags) ? session[:tags] : []
      if params['overwrite_type']
        types = new_tags.map{|t| t.split(':')[0]}
        tags.delete_if {|t| types.include?(t.split(':')[0])}
      end
      tags |= new_tags
      session[:tags] = tags
    end

    render :json => { :success => true, :user_tags => tags}
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
