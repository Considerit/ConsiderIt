require 'cgi'

class HtmlController < ApplicationController
  #respond_to :html
  before_action :verify_user

  def index

    # if someone has accessed a non-existent subdomain or the mime type isn't HTML (must be accessing a nonexistent file)
    # Note: I removed the text/html constraint because of problems oneboxing from discourse
    #if !current_subdomain || request.format.to_s != 'text/html' || request.fullpath.include?('data:image')
    if !current_subdomain || request.fullpath.include?('data:image')    
      render :file => "#{Rails.root}/public/404.html", :layout => false, :status => :not_found
      return
    end

    if current_subdomain.SSO_domain && !current_user.registered
      initiate_saml_auth
      return
    end

    if Rails.env.development? || request.host.end_with?('chlk.it')
      if params[:domain]
        session[:default_subdomain] = Subdomain.find_by_name(params[:domain]).id
        redirect_to request.path    
        return
      end
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

    
    @js = "/#{manifest['franklin']}"
    @vendor = ''

    if Rails.application.config.action_controller.asset_host
      @js = "https:#{Rails.application.config.action_controller.asset_host}#{@js}"
      @vendor = 'https:' + Rails.application.config.action_controller.asset_host
    end


    if current_subdomain.customizations
      customization_obj = current_subdomain.customizations.gsub '"', '\\"'
      customization_obj = "{\n#{customization_obj}\n}"
    else 
      customization_obj = "{}"
    end

    dirty_key '/asset_manifest'

    # CSP policy if we ever want to implement in future
    # protocol = request.protocol == 'https:' ? 'https' : 'http:' 
    # csp = "default-src 'self'; connect-src 'self' #{protocol}//translate.googleapis.com; font-src 'self' #{protocol}//d2rtgkroh5y135.cloudfront.net #{protocol}//fonts.gstatic.com #{protocol}//fast.fonts.net #{protocol}//maxcdn.bootstrapcdn.com; media-src *; object-src 'self' *; frame-src *; img-src 'self' data: * #{protocol}//d2rtgkroh5y135.cloudfront.net #{protocol}//translate.googleapis.com #{protocol}//www.google-analytics.com #{protocol}//www.google.com #{protocol}//www.gstatic.com; script-src 'self' 'unsafe-inline' 'unsafe-eval' #{protocol}//cdnjs.cloudflare.com/ #{protocol}//d2rtgkroh5y135.cloudfront.net/ #{protocol}//translate.google.com/ #{protocol}//translate.googleapis.com/ #{protocol}//www.google-analytics.com/; style-src 'self' 'unsafe-inline' * #{protocol}//fast.fonts.net/ #{protocol}//fonts.googleapis.com/ #{protocol}//maxcdn.bootstrapcdn.com/ #{protocol}//translate.googleapis.com/"

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
    google_verification = nil

    @favicon = "/favicon.ico"

    # subdomain defaults
    case current_subdomain.name
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

    else
      title = current_subdomain.branding_info['masthead_header_text']
      if !title or title.length == 0 
        title = current_subdomain['app_title'] or "#{current_subdomain.name}"
      end
      image = current_subdomain.branding_info['logo']
      if image && image[0] != '/' && !image.index('http')
        image = "#{request.protocol}#{Rails.application.config.action_controller.asset_host or 'localhost:3000'}#{image}"
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
      @host = current_subdomain.host_with_port
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
