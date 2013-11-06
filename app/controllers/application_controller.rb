require 'digest/md5'

class ApplicationController < ActionController::Base
  #protect_from_forgery
  set_current_tenant_through_filter
  prepend_before_filter :get_current_tenant
  before_filter :theme_resolver
  after_filter  :pageview
  include CacheableCSRFTokenRails

  def render(*args)
    if Rails.cache.read("avatar-digest-#{current_tenant.id}").nil?
      Rails.cache.write("avatar-digest-#{current_tenant.id}", 0)
    end
    
    #############
    # for testing pinned users: 
    test_fixed_user = false
    if Rails.env == 'development' && test_fixed_user
      if false
        @limited_user = User.find(6)
        @limited_user_email = @limited_user.email
        @limited_user_follows = @limited_user.follows.all
      else
        @limited_user_email = 'test@testing.dev'
      end
    end
    ###################

    if params.has_key?('u') && params.has_key?('t') && params['t'].length > 0
      user = User.find_by_lower_email(params[:u])

      # pp ApplicationController.arbitrary_token("#{user.email}#{user.unique_token}#{current_tenant.identifier}") if !user.nil?
      # pp ApplicationController.arbitrary_token("#{params[:u]}#{current_tenant.identifier}") if user.nil?


      permission =   (user.nil? && ApplicationController.arbitrary_token("#{params[:u]}#{current_tenant.identifier}") == params[:t]) \
                  ||(!user.nil? && ApplicationController.arbitrary_token("#{params[:u]}#{user.unique_token}#{current_tenant.identifier}") == params[:t]) # this user already exists, want to have a harder auth method; still not secure if user forwards their email

      if permission
        session[:limited_user] = user ? user.id : nil
        @limited_user_follows = user ? user.follows.all : []
        @limited_user = user
        @limited_user_email = params[:u]
      end
    elsif session.has_key?(:limited_user ) && !session[:limited_user].nil?
      @limited_user = User.find(session[:limited_user])
      @limited_user_follows = @limited_user.follows.all
      @limited_user_email = @limited_user.email
    end

    #TODO: what does this do?
    if args && args.first.respond_to?('has_key?')
      args.first[:layout] = false if request.xhr? and args.first[:layout].nil?
    else
      args.append({:layout => false}) if request.xhr?
    end

    if current_tenant.host.nil?
      current_tenant.host = request.host
      current_tenant.host_with_port = request.host_with_port
      current_tenant.save
    end

    # Destroy the current user if a request is made to the server when the user has yet
    # to complete their registration. There are no legit reasons for a refresh to occur, 
    # and many illegimate ones. 
    if !request.env.has_key?("omniauth.auth") && !request.xhr? && current_user && !current_user.registration_complete
      user = current_user
      Devise.sign_out_all_scopes ? sign_out : sign_out('user')
      user.destroy
    end

    #TODO: now that we have a global redirect to home#index for non-ajax requests, can we move this to home controller?
    if !request.xhr?
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
          description = current_tenant.header_text
          if current_tenant.header_details_text && current_tenant.header_details_text != ''
            description = "#{description} - #{current_tenant.header_details_text}"
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
      ######


      if params.has_key? :reset_password_token
        @reset_password_token = params[:reset_password_token]
      end

      @users = ActiveSupport::JSON.encode(ActiveRecord::Base.connection.select( "SELECT id,name,avatar_file_name,created_at, metric_influence, metric_points, metric_conversations,metric_positions,metric_comments FROM users WHERE account_id=#{current_tenant.id}"))
      @proposals = []


      num_proposals_per_page = current_tenant.num_proposals_per_page
      
      proposals = Proposal.open_to_public.active.browsable
      proposals_active_count = proposals.count
      proposals = proposals.public_fields.order('activity DESC').limit(num_proposals_per_page)


      top = []
      top_con_qry = proposals.where 'top_con IS NOT NULL'
      if top_con_qry.count > 0
        top += top_con_qry.select(:top_con).map {|x| x.top_con}.compact
      end

      top_pro_qry = proposals.where 'top_pro IS NOT NULL' 
      if top_pro_qry.count > 0
        top += top_pro_qry.select(:top_pro).map {|x| x.top_pro}.compact
      end
      
      top_points = {}
      Point.where('id in (?)', top).public_fields.each do |pnt|
        top_points[pnt.id] = pnt
      end

      if current_user
        hidden_proposals = Proposal.content_for_user(current_user)
        hidden_proposals.each do |hidden|          
          top_points[hidden.top_pro] = Point.find(hidden.top_pro) if hidden.top_pro
          top_points[hidden.top_con] = Point.find(hidden.top_con) if hidden.top_con
        end
        proposals += hidden_proposals
      end

      proposals_inactive_count = Proposal.open_to_public.inactive.browsable.count

      @proposals = {
        :proposals => proposals,
        :points => top_points.values,
        :proposals_active_count => proposals_active_count,
        :proposals_inactive_count => proposals_inactive_count
      }

      @public_root = Rails.application.config.action_controller.asset_host.nil? ? "" : Rails.application.config.action_controller.asset_host

    end

    super

  end

  def self.find_current_tenant(rq)
    tenant = Account.find_by_identifier(rq.session[:user_account_identifier]) 
    if tenant.nil?
      tenant = Account.find(1)
    end
    tenant
  end

  def current_ability
    @current_ability ||= Ability.new(current_user, current_tenant, request.session_options[:id], params)
  end

  def mail_options
    {:host => request.host,
     :host_with_port => request.host_with_port,
     :from => current_tenant.contact_email && current_tenant.contact_email.length > 0 ? current_tenant.contact_email : APP_CONFIG[:admin_email],
     :app_title => current_tenant.app_title,
     :current_tenant => current_tenant
    }
  end

  def self.token_for_action(user_id, object, action)
    user = User.find(user_id.to_i)
    Digest::MD5.hexdigest("#{user.unique_token}#{object.id}#{object.class.name}#{action}")
  end

  def self.arbitrary_token(key)
    Digest::MD5.hexdigest(key)
  end

  def self.reset_user_activities(session, proposal)
    session[proposal.id] = {
      :included_points => {},
      :deleted_points => {},
      :written_points => [],
      :viewed_points => []
    }
  end

private

  def get_current_tenant(rq = nil)
    rq ||= request
    current_account = rq.subdomain.nil? || rq.subdomain.length == 0 ? Account.find(1) : Account.find_by_identifier(rq.subdomain)

    current_account = Account.find(1) if current_account.nil?
    
    set_current_tenant(current_account)
    session["user_account_identifier"] = current_tenant.identifier
    current_account
  end

  def theme_resolver

    if !session.has_key?('user_theme') || current_tenant.theme != session["user_theme"]
      session["user_theme"] = current_tenant.theme
    end
    
    if !current_tenant.inherited_themes.nil?
      current_tenant.inherited_themes.split(':').each do |parent_theme|
        add_theme_view_path_for(parent_theme)
      end
    end

    set_theme(session["user_theme"])
  end

  def store_location(path)
    session[:return_to] = path
  end

  def current_admin_user
    current_user
  end

  def pageview
    user = current_user ? current_user.id : nil
    params = {
      :account_id => current_tenant.id,
      :user_id => user,
      :referer => request.referrer,
      :session => request.session_options[:id],
      :url => request.fullpath,
      :ip_address => request.remote_ip,
      :user_agent => request.env["HTTP_USER_AGENT"],
      :created_at => Time.current
    }  

    PageView.create! params
  end


end
