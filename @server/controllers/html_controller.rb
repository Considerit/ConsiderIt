require 'cgi'

class HtmlController < ApplicationController
  before_action :verify_user

  def index

    if Rails.env.development? && params[:domain]
      candidate_subdomain = Subdomain.find_by_name(params[:domain])
      if candidate_subdomain && session[:default_subdomain] != params[:domain]
        session[:default_subdomain] = candidate_subdomain.name
        redirect_to request.fullpath 
        return
      end
    end

    # if someone has accessed a non-existent subdomain or the mime type isn't HTML (must be accessing a nonexistent file)
    # Note: The text/html constraint creates problems oneboxing from discourse. I'm adding it back in, but mess around 
    # with that if we ever need the oneboxing and it is not working.
    # if !current_subdomain || request.fullpath.include?('data:image')    
    if !current_subdomain || request.format.to_s != 'text/html' || request.fullpath.include?('data:image')
      render :file => "#{Rails.root}/public/404.html", :layout => false, :status => :not_found
      return
    end

    if current_subdomain.SSO_domain && !current_user.registered && request.path != '/'
      initiate_saml_auth
      return
    end

    if !session.has_key?(:search_bot)
      session[:search_bot] = !!request.fullpath.match('_escaped_fragment_')  \
                             || !request.user_agent
    end
    
    # used by the layout
    @meta, @page, @title = get_meta_data()
    @is_search_bot = session[:search_bot]


    if !session[:search_bot]
      referer = params.has_key?('u') ? 'from email notification' : request.referer

      current_user.add_to_active_in
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

    manifest = JSON.parse(File.open("public/build/manifest.json", "rb") {|io| io.read})

    
    if current_subdomain.name == 'homepage'
      @app = "product_page"
      @google_analytics_code = APP_CONFIG[:google_analytics_product]
      @js_dependencies = "/#{manifest['product_page_dependencies']}"
      if APP_CONFIG[:google_ads]
        @google_ads_id = APP_CONFIG[:google_ads]
      end
    else 
      @app = "franklin"
      @google_analytics_code = APP_CONFIG[:google_analytics]
      @js_dependencies = nil
    end 

    @js = "/#{manifest[@app]}"

    @vendor = ''

    if Rails.application.config.action_controller.asset_host
      @js = "https:#{Rails.application.config.action_controller.asset_host}#{@js}"
      @vendor = 'https:' + Rails.application.config.action_controller.asset_host
    end

    # CSP policy if we ever want to implement in future
    # protocol = request.protocol == 'https:' ? 'https' : 'http:' 
    # csp = "default-src 'self'; connect-src 'self' #{protocol}//translate.googleapis.com; font-src 'self' #{protocol}//d2rtgkroh5y135.cloudfront.net #{protocol}//fonts.gstatic.com #{protocol}//maxcdn.bootstrapcdn.com; media-src *; object-src 'self' *; frame-src *; img-src 'self' data: * #{protocol}//d2rtgkroh5y135.cloudfront.net #{protocol}//translate.googleapis.com #{protocol}//www.google-analytics.com #{protocol}//www.google.com #{protocol}//www.gstatic.com; script-src 'self' 'unsafe-inline' 'unsafe-eval' #{protocol}//cdnjs.cloudflare.com/ #{protocol}//d2rtgkroh5y135.cloudfront.net/ #{protocol}//translate.google.com/ #{protocol}//translate.googleapis.com/ #{protocol}//www.google-analytics.com/; style-src 'self' 'unsafe-inline' * #{protocol}//fonts.googleapis.com/ #{protocol}//maxcdn.bootstrapcdn.com/ #{protocol}//translate.googleapis.com/"

    # if false && current_subdomain.name == 'internethealthreport'
    #   response.headers["Content-Security-Policy"] = csp 
    # else       
    #   response.headers["Content-Security-Policy-Report-Only"] = csp 
    # end

    render "layouts/application", :layout => false
  end



  private


  #### Set meta tag info ####
  # Hardcoded for now. 
  # TODO: store subdomain meta data in the database
  def get_meta_data

    page = request.path
    
    proposal = nil
    keywords = title = nil
    google_verification = APP_CONFIG[:google_site_verification]
    canonical = nil

    @favicon = "/favicon.ico"

    # subdomain defaults
    case current_subdomain.name

    when 'homepage'
      @canonical = "#{request.protocol}#{request.host}#{page}"

      case page 

        when "/tour"
          title = 'Consider.it is the only forum to visually summarize what your community thinks and why'
          description = "Explore the features of Consider.it and what it takes to host a Consider.it forum. Includes a comparison guide between Consider.it, surveys, and standard web forums."


        when "/examples", "/examples/public_engagement"
          title = 'Join Seattle in using Consider.it for public engagement'
          description = "Public engagement on housing, transportation, climate and more. Collect demographic data to understand who you're reaching. Understand what different groups think, and why."
          @canonical = "#{request.protocol}#{request.host}/examples/public_engagement"
        when "/examples/strategic_planning"
          title = 'Engage stakeholders during strategic planning'
          description = "Involve staff and other stakeholders in major strategy decisions to learn, decide, and gain buy-in. Compare opinions of staff, board, donors, and others."

        when "/examples/community_visioning"
          title = 'Use Consider.it for community ideation and deliberation as you help mobilize action.'
          description = "\"Coordinate a community-wide conversation in a way that’s easy for participants and productive for organizers.\" – Kēhau Abad, ʻĀina Aloha Economic Futures"

        when "/examples/decentralized_decisions"
          title = 'Community prioritization and decision-making at scale, without hierarchy.'
          description = "\"Consider.it’s careful design choices were critical for not only aggregating community opinions, but also in understanding the rationale.\" – Auryn Macmillan, Gnosis"

        when "/create_forum"
        when "/contact"
        when "/pricing"

        else
          title = 'Consider.it: An Online Forum for Community Engagement'
          description = "Want to easily understand what your community thinks and why? Consider.it can help. Supports civil and focused stakeholder dialogue, even when hundreds participate."
                        #"A web forum that elevates your community's opinions. Civil and focused discussion even when hundreds of stakeholders participate. Great for public engagement and community ideation."
      end
      image = "#{request.protocol}#{view_context.asset_path('images/product_page/galacticfederation.png').gsub(/\/\//,'')}"
      keywords = "online engagement, public engagement tool, community engagement tool, stakeholder engagement tool, deliberation tool, ideation platform, community ideation, public engagement, community engagement, stakeholder engagement, online forum, online deliberation, online dialogue, feedback tool"

    when 'newblueplan'
      title = 'New Blue Plan for Retaking Washington'
      image = "#{request.protocol}#{view_context.asset_path('images/wa-dems/activity.png').gsub(/\/\//,'')}"
      description = "Your party, your plan. How can we work together to win in every race across Washington? Share your ideas!"
      keywords = "washington democrats, washington democratic party, democratic party, washington, Manka Dhingra, Michelle Rylands, Karen Hardy, planning, election, campaigning, 2017, 2018, resistance"

    when 'internethealthreport'
      title = 'How would you measure the health of the Internet?'
      description = "Tell us how you think Mozilla’s Internet Health Report should document and explain the Internet from year to year."
      keywords = "Internet health, Internet, Mozilla, Internet research, privacy, decentralization, digital inclusion, Web literacy, digital divide, digital rights"
      @favicon = '/images/internethealthreport/favicon.png'

    when 'seattlefoodactionplan'
      title = "What do you think of the Seattle Food Action Plan?"
      description = "We’re updating Seattle’s Food Action Plan and want to hear from you! Provide us your feedback now through August 26"
      image = "#{request.protocol}#{view_context.asset_path('images/seattlefoodactionplan/socialmedia.png').gsub(/\/\//,'')}"

    else
      banner = current_subdomain.customization_json['banner'] || {}
      title = banner.fetch('title', current_subdomain.name)

      image = current_subdomain.logo_file_name
      if image && image[0] != '/' && !image.index('http')
        image = "#{request.protocol}#{Rails.application.config.action_controller.asset_host || 'localhost:3000'}#{image}"
      end 
      cnt = Proposal.active.count
      if cnt == 1
        description = "One proposal is being considered."
      else 
        description = "#{cnt} proposals are being considered."
      end 
    end

    # proposal overrides, if the current page is a proposal
    proposal = Proposal.find_by_slug page[1..page.length] if page != '/' && page != '/about'
    if proposal 
      title = proposal.name
      title = proposal.seo_title || title
      description = proposal.seo_description || "#{proposal.description || proposal.name}"

      parts = description.split('<br>')

      if parts.length > 1
        description = parts[0] + '...'
      end

      description = ActionView::Base.full_sanitizer.sanitize description
      keywords = proposal.seo_keywords if proposal.seo_keywords

      @proposal = proposal
      @host = current_subdomain.url
      @oembed_url = CGI.escape "https://" + @host + "/" + @proposal.slug + "?results=true"
    end

    meta = [
      { :name => 'title', :content => title },
      { :name => 'description', :content => description },
      { :name => 'keywords', :content => keywords },

      { :name => 'forum', :content => current_subdomain.id },

      { :property => 'og:title', :content => title },
      { :property => 'og:description', :content => description },
      { :property => 'og:url', :content => request.original_url().split('?')[0] },
      { :property => 'og:type', :content => 'website' },
      { :property => 'og:site_name', :content => (title or "#{current_subdomain.name} discussion") },

      { :name => 'twitter:card', :content => 'summary' },
      { :name => 'twitter:title', :content => title },
      { :name => 'twitter:description', :content => description },

      { :property => 'fb:app_id', :content => "206466936144360" },
    ]

    if image 
      meta.append({ :property => 'og:image', :content => image })
      meta.append({ :property => 'og:image:secure_url', :content => image })
      meta.append({ :name => 'twitter:image', :content => image })

    end 

    if google_verification
      meta.append({:name => "google-site-verification", :content => google_verification })
    end

    return meta, page, title
  end

end
