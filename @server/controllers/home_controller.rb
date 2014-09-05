
class HomeController < ApplicationController
  caches_action :avatars, :cache_path => proc {|c|
    {:tag => "avatars-#{current_tenant.id}-#{Rails.cache.read("avatar-digest-#{current_tenant.id}")}"}
  }

  def index
    # We don't have a homepage. In the iterim, let's just redirect 
    # accesses to the homepage to the latest published proposal
    # TODO: better way of knowing if a particular customer has a homepage or not.
    if current_tenant.id != 1 && request.path == '/' && request.query_string == ""
      proposal = current_tenant.proposals.open_to_public.active.last
      redirect_to "/#{proposal.long_id}"
      return
    end

    response.headers["Strict Transport Security"] = 'max-age=0'
    
    @page = request.path


    #### Setting meta tag info ####
    if APP_CONFIG[:meta].has_key? current_tenant.identifier.intern
      meta = APP_CONFIG[:meta][current_tenant.identifier.intern]
      using_default_meta = false
    else 
      meta = APP_CONFIG[:meta][:default]
      using_default_meta = true
    end

    if using_default_meta
      @title = current_tenant.app_title || meta[:title]
      if current_tenant.header_text
        description = ActionView::Base.full_sanitizer.sanitize(current_tenant.header_text, :tags=>[])  
        if current_tenant.header_details_text && current_tenant.header_details_text != ''
          description = "#{description} - #{ActionView::Base.full_sanitizer.sanitize(current_tenant.header_details_text, :tags=>[])}"
        end
      else
        description = meta[:description]
      end
    else
      @title = meta[:title] || current_tenant.app_title
      description = meta[:description]
    end

    @title = @title.strip
    @keywords = meta[:keywords].strip
    @description = description.strip


    render "layouts/application", :layout => false
  end

  def activemike
    render "layouts/testmike", :layout => false
  end

  def avatars
    #result = render_to_string :partial => './avatars'
    respond_to do |format|
      format.html { render :partial => './avatars' } 
      format.json { render :partial => './avatars' }
    end
  end

end
