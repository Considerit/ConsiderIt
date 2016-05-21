require 'cgi'

class HtmlController < ApplicationController
  respond_to :html
  before_action :verify_user

  def index

    # if someone has accessed a non-existent subdomain or the mime type isn't HTML (must be accessing a nonexistent file)
    if !current_subdomain || request.format.to_s != 'text/html' || request.fullpath.include?('data:image')
      render :file => "#{Rails.root}/public/404.html", :layout => false, :status => :not_found
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

    if !session.has_key? :app
      session[:app] = 'franklin'
    elsif session[:app] == 'saas_landing_page'
      # migration. This can be eliminated Junish
      session[:app] = 'product_page'
    end

    @app = if current_subdomain.name == 'homepage' || session[:app] == 'product_page'
              'product_page'
           else
              'franklin'
           end


    manifest = JSON.parse(File.open("public/build/manifest.json", "rb") {|io| io.read})

    if Rails.application.config.action_controller.asset_host
      @js = "#{Rails.application.config.action_controller.asset_host}/#{manifest[@app]}"
    else 
      @js = "/#{manifest[@app]}"
    end

    dirty_key '/asset_manifest'
    response.headers["Strict Transport Security"] = 'max-age=0'

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

    # subdomain defaults
    case current_subdomain.name
    when 'livingvotersguide'
      title = 'Washington Voters Guide for the 2015 Election'
      image = view_context.asset_path 'livingvotersguide/logo.png'
      description = "Washington's Citizen-powered Voters Guide: learn about your ballot, decide how you’ll vote, and share your opinion. Currently focused on the 2015 Seattle City Council primary election."
      keywords = "voting,voters guide,online voters guide,2015,ballot,washington,primary election, primaries, general election, washington state,election,pamphlet,voters pamphlet,ballot measures,citizen,initiatives,propositions,2015 elections,online voter pamphlet,voting facts,voters information,voting ballot 2015,voting information 2015,information about voting,election dates,electoral ballot,wa,seattle,tacoma,spokane,yakima,vancouver"
      fb_app_id = '159147864098005'
    when 'cityoftigard'
      title = "City of Tigard Dialogue"
      image = view_context.asset_path 'cityoftigard/logo.png'
      description = "Dialogue about City of Tigard"
    when 'homepage'
      title = 'Consider.it | Think Better Together'
      image = view_context.asset_path 'product_page/logo.png'
      description = "Consider.it is the first forum that works better when more people participate. Use it in your community, organization or classroom. "
      keywords = "discussion,forum,feedback,decision making,governance,feedback,collect feedback,deliberation,public engagement,impact assessment,strategic planning,process improvement,standards,stakeholder committee,Common Core,listening"
      google_verification = "gd89L8El1xxxBpOUk9czjE9zZF4nh8Dc9izzbxIRmuY"
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

      @proposal = proposal
      @host = current_subdomain.host_with_port
      @oembed_url = CGI.escape "https://" + @host + "/" + @proposal.slug + "?results=true"
    end

    meta = [
      # { :name => 'title', :content => title },
      # { :name => 'twitter:title', :content => title },
      # { :property => 'http://ogp.me/ns#title', :content => title },

      # { :name => 'description', :content => description },
      # { :name => 'twitter:description', :content => description },
      # { :property => 'http://ogp.me/ns#description', :content => description },

      { :name => 'keywords', :content => keywords },

      # { :property => 'http://ogp.me/ns#url', :content => request.original_url() },
      # { :property => 'http://ogp.me/ns#image', :content => image },

      # { :property => 'http://ogp.me/ns#type', :content => 'website' },
      # { :property => 'http://ogp.me/ns#site_name', :content => (current_subdomain.app_title or "#{current_subdomain.name} discussion") },

      # { :name => 'twitter:card', :content => 'summary' },
      # { :property => 'https://www.facebook.com/2008/fbml#app_id', :content => fb_app_id }

    ]

    if google_verification
      meta.append({:name => "google-site-verification", :content => google_verification })
    end

    return meta, page, title
  end

end
