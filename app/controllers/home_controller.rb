class HomeController < ApplicationController
  #caches_page :index

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

    respond_to do |format|
      format.html
    end

  end

  def avatars
    #result = render_to_string :partial => 'home/avatars'
    respond_to do |format|
      format.html { render :partial => 'home/avatars' } 
      format.json { render :partial => 'home/avatars' }
    end
  end

  def content_for_user
    # proposals that are written by this user; private proposals this user has access to
    proposals = Proposal.content_for_user(current_user)

    top = []

    proposals.each do |prop|
      top.push(prop.top_con) if prop.top_con
      top.push(prop.top_pro) if prop.top_pro
    end

    points = {}
    Point.where('id in (?)', top).public_fields.each do |pnt|
      points[pnt.id] = pnt
    end

    current_user.points.published.where(:hide_name => true).public_fields.each do |pnt|
      points[pnt.id] = pnt
    end

    respond_to do |format|
      format.json {
        render :json => {
          :points => points.values,
          :proposals => proposals
        }
      }
    end
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

    respond_to do |format|
      format.json { render :json => { :success => true, :user_tags => tags} }
    end
  end  

  # def study
  #   category = params[:category]
  #   sd = StudyData.create!({
  #     :category => category.to_i,
  #     :user_id => current_user ? current_user.id : nil,
  #     :session_id => request.session_options[:id],

  #     :position_id => params[:position_id],
  #     :point_id => params[:point_id],
  #     :proposal_id => params[:proposal_id],
  #     :detail1 => params[:detail1],
  #     :detail2 => params[:detail2],
  #     :ival => params[:ival].to_i,
  #     :fval => params[:fval].to_f,
  #     :bval => params[:bval] == 'true'
  #   })
  #   response = {:success => "success"}
  #   render :json => response.to_json

  # end

end
