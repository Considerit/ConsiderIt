class HtmlController < ApplicationController
  respond_to :html

  def index

    # if someone has accessed a non-existent subdomain or the mime type isn't HTML (must be accessing a nonexistent file)
    if !current_subdomain || request.format.to_s != 'text/html' || request.fullpath.include?('data:image')
      render :file => "#{Rails.root}/public/404.html", :layout => false, :status => :not_found
      return
    end

    # Storing the full host name on the subdomain object.
    # This is needed because we don't have a request
    # when sending emails out at later points. 
    # This is ugly, would be nice to eliminate this. 
    if current_subdomain.host.nil?
      current_subdomain.host = request.host
      current_subdomain.host_with_port = request.host_with_port
      current_subdomain.save
    end

    # Query parameters from an email link.    
    # Store query parameters important for access control for email notifications
    if params.has_key?('u') && params.has_key?('t') && params['t'].length > 0
      session[:email_token_user] = {'u' => params['u'], 't' => params['t']}
      
      # Verify whether this user controls this account
      verify_user_email_if_possible
    end

    if !session.has_key?(:search_bot)
      #session[:search_bot] = !!request.fullpath.match('_escaped_fragment_') || (request.user_agent && !!request.user_agent.match('Prerender'))
      session[:search_bot] = !!request.fullpath.match('_escaped_fragment_')  \
                             || !request.user_agent #\
                             #|| !!request.user_agent.match('Prerender') \
                             #|| !!request.user_agent.match(/\(.*https?:\/\/.*\)/) #http://stackoverflow.com/questions/5882264/ruby-on-rails-how-to-determine-if-a-request-was-made-by-a-robot-or-search-engin
    end

    # Some subdomains don't have a homepage. In the iterim, let's just redirect 
    # accesses to the homepage to the latest published proposal
    # TODO: better way of knowing if a particular subdomain has a homepage or not.
    # if current_subdomain.name == 'cityoftigard' && request.path == '/' && request.query_string == "" && !session[:search_bot]
    #   proposal = current_subdomain.proposals.open_to_public.active.last
    #   if proposal
    #     redirect_to "/#{proposal.slug}"
    #   else
    #     render :file => "#{Rails.root}/public/404.html", :layout => false, :status => :not_found
    #   end
    #   return
    # end
    
    # used by the layout
    @meta, @page, @title = get_meta_data()
    @is_search_bot = session[:search_bot]


    if !session[:search_bot]
      referer = session.has_key?(:email_token_user) ? 'from email notification' : request.referer
      write_to_log({
        :what => 'landed on site',
        :where => request.fullpath,
        :details => {
          :referer => referer, 
          :ip => request.remote_ip, 
          :user_agent => request.env["HTTP_USER_AGENT"]
        }
      })
    end

    response.headers["Strict Transport Security"] = 'max-age=0'

    if current_subdomain.name == 'homepage' && request.path == '/'
      render "layouts/homepage", :layout => false
    else
      render "layouts/application", :layout => false
    end
  end


  def activemike
    render "layouts/testmike", :layout => false
  end


  private

  #### Set meta tag info ####
  # Hardcoded for now. 
  # TODO: store subdomain meta data in the database
  def get_meta_data

    page = request.path
    
    proposal = nil
    keywords = title = nil

    # subdomain defaults
    case current_subdomain.name
    when 'livingvotersguide'
      title = 'Washington Voters Guide for the 2014 Election'
      image = view_context.asset_path 'livingvotersguide/logo.png'
      description = "Washington's Citizen-powered Voters Guide. Decide for yourself about the issues on your 2014 ballot, with a little help from your neighbors."
      keywords = "voting,voters guide,online voters guide,2014,ballot,washington,washington state,election,pamphlet,voters pamphlet,ballot measures,citizen,initiatives,propositions,2014 elections,online voter pamphlet,voting facts,voters information,voting ballot 2014,voting information 2014,information about voting,election dates,electoral ballot,wa,seattle,tacoma,spokane,yakima,vancouver"
      fb_app_id = '159147864098005'
    when 'cityoftigard'
      title = "City of Tigard Dialogue"
      image = view_context.asset_path 'cityoftigard/logo.png'
      description = "Dialogue about City of Tigard"
    else
      title = current_subdomain.app_title or "#{current_subdomain.name} discussion"
      image = nil
      description = "Help think through these issues being considered."
    end

    # proposal overrides, if the current page is a proposal
    proposal = Proposal.find_by_slug page[1..page.length] if page != '/' && page != '/about'
    if proposal 
      title = proposal.name
      if proposal.category && proposal.designator
        title = "#{proposal.category[0]}-#{proposal.designator}: #{title}"
      end
      title = proposal.seo_title || title
      description = proposal.seo_description || "What do you think? #{proposal.description || proposal.name}"
      description = ActionView::Base.full_sanitizer.sanitize description
      keywords = proposal.seo_keywords if proposal.seo_keywords
    end

    meta = [
      { :name => 'title', :content => title },
      { :name => 'twitter:title', :content => title },
      { :property => 'og:title', :content => title },

      { :name => 'description', :content => description },
      { :name => 'twitter:description', :content => description },
      { :property => 'og:description', :content => description },

      { :name => 'keywords', :content => keywords },

      { :property => 'og:url', :content => request.original_url() },
      { :property => 'og:image', :content => image },

      { :property => 'og:type', :content => 'website' },
      { :property => 'og:site_name', :content => (current_subdomain.app_title or "#{current_subdomain.name} discussion") },

      { :name => 'twitter:card', :content => 'summary' },
      { :property => 'fb:app_id', :content => fb_app_id }

    ]

    return meta, page, title
  end

end
