class HomeController < ApplicationController
  caches_action :avatars, :cache_path => proc {|c|
    {:tag => "avatars-#{current_tenant.id}-#{Rails.cache.read("avatar-digest-#{current_tenant.id}")}"}
  }


  # this method serves pretty much all HTML requests coming through the application
  def index

    #TODO: do something special for non-root pages?

    if APP_CONFIG[:meta].has_key? current_tenant.identifier.intern
      meta = APP_CONFIG[:meta][current_tenant.identifier.intern]
    else 
      meta = APP_CONFIG[:meta][:default]
    end

    if current_tenant.header_text
      description = current_tenant.header_text
      if current_tenant.header_details_text && current_tenant.header_details_text != ''
        description = "#{description} - #{current_tenant.header_details_text}"
      end
    else
      description = meta[:description]
    end

    @title = current_tenant.app_title || meta[:title]
    @keywords = meta[:keywords]
    @description = description

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
  # TODO: move this to a taggable controller, and specify the model type being tagged
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

end
