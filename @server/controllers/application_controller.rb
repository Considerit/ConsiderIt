require 'digest/md5'

class ApplicationController < ActionController::Base
  #protect_from_forgery
  set_current_tenant_through_filter
  prepend_before_action :get_current_tenant
  before_action :theme_resolver
  before_action :init_thread_globals
  after_action  :pageview
  #include CacheableCSRFTokenRails

  def render(*args)
    if Rails.cache.read("avatar-digest-#{current_tenant.id}").nil?
      Rails.cache.write("avatar-digest-#{current_tenant.id}", 0)
    end
    

    if params.has_key?('u') && params.has_key?('t') && params['t'].length > 0
      user = User.find_by_lower_email(params[:u])

      # for testing private discussions
      # pp ApplicationController.arbitrary_token("#{user.email}#{user.unique_token}#{current_tenant.identifier}") if !user.nil?
      # pp ApplicationController.arbitrary_token("#{params[:u]}#{current_tenant.identifier}") if user.nil?


      # is it a security problem to allow users to continue to sign in through the tokenized email after they've created an account?
      permission =   (ApplicationController.arbitrary_token("#{params[:u]}#{current_tenant.identifier}") == params[:t]) \
                  ||(!user.nil? && ApplicationController.arbitrary_token("#{params[:u]}#{user.unique_token}#{current_tenant.identifier}") == params[:t]) # this user already exists, want to have a harder auth method; still not secure if user forwards their email

      if permission
        session[:limited_user] = user ? user.id : nil
        @limited_user_follows = user ? user.follows.to_a : []
        @limited_user = user
        @limited_user_email = params[:u]
      end
    elsif session.has_key?(:limited_user ) && !session[:limited_user].nil?
      @limited_user = User.find(session[:limited_user])
      @limited_user_follows = @limited_user.follows.to_a
      @limited_user_email = @limited_user.email
    end

    #TODO: what does this do?
    if args && args.first.respond_to?('has_key?')
      args.first[:layout] = false if request.xhr? && args.first[:layout].nil?
    elsif args && args.last.respond_to?('has_key?')
      args.last[:layout] = false if request.xhr? && args.last[:layout].nil?
    else
      args.append({:layout => false}) if request.xhr?
    end

    if current_tenant.host.nil?
      current_tenant.host = request.host
      current_tenant.host_with_port = request.host_with_port
      current_tenant.save
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
      ######

      # @users = ActiveSupport::JSON.encode(ActiveRecord::Base.connection.select( "SELECT id,name,avatar_file_name,created_at, metric_influence, metric_points, metric_conversations,metric_opinions,metric_comments FROM users WHERE account_id=#{current_tenant.id}"))
      
      # active_proposals = Proposal.open_to_public.active.browsable
      # inactive_proposals = Proposal.open_to_public.inactive.browsable

      # proposals_active_count = active_proposals.count
      # proposals_inactive_count = inactive_proposals.count


      # proposals = current_tenant.enable_hibernation ? inactive_proposals : active_proposals


      # top = []
      # top_con_qry = proposals.where 'top_con IS NOT NULL'
      # if top_con_qry.count > 0
      #   top += top_con_qry.select(:top_con).map {|x| x.top_con}.compact
      # end

      # top_pro_qry = proposals.where 'top_pro IS NOT NULL' 
      # if top_pro_qry.count > 0
      #   top += top_pro_qry.select(:top_pro).map {|x| x.top_pro}.compact
      # end
      
      # top_points = {}
      # Point.where('id in (?)', top).public_fields.each do |pnt|
      #   top_points[pnt.id] = pnt
      # end

      # @opinions = {}
      # if current_user
      #   hidden_proposals = Proposal.content_for_user(current_user)
      #   hidden_proposals.each do |hidden|          
      #     top_points[hidden.top_pro] = Point.find(hidden.top_pro) if hidden.top_pro
      #     top_points[hidden.top_con] = Point.find(hidden.top_con) if hidden.top_con
      #   end
      #   proposals += hidden_proposals
      #   @opinions = current_user.opinions.published
      # end


      # @proposals = {
      #   :proposals => proposals,
      #   :points => top_points.values,
      #   :proposals_active_count => proposals_active_count,
      #   :proposals_inactive_count => proposals_inactive_count,
      # }

      # @public_root = Rails.application.config.action_controller.asset_host.nil? ? "" : Rails.application.config.action_controller.asset_host

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
    @current_ability ||= Ability.new(current_user, current_tenant, request.session_options[:id], session, params)
  end

  def mail_options
    {:host => request.host,
     :host_with_port => request.host_with_port,
     :from => current_tenant.contact_email && current_tenant.contact_email.length > 0 ? current_tenant.contact_email : APP_CONFIG[:email],
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
    
    # if !current_tenant.inherited_themes.nil?
    #   current_tenant.inherited_themes.split(':').each do |parent_theme|
    #     add_theme_view_path_for(parent_theme)
    #   end
    # end

    # set_theme(session["user_theme"])
  end

  def init_thread_globals
    # Make things to remember changes
    Thread.current[:dirtied_keys] = {}
    Thread.current[:tenant] = current_tenant
    Thread.current[:mail_options] = mail_options

    puts("In before: is there a current user? '#{session[:current_user_id2]}'")
    if not session[:current_user_id2]
      new_current_user()
    end
    Thread.current[:current_user_id2] = session[:current_user_id2]

    # Remap crap:
    # Thread.current[:remapped_keys] = {}
    # # Remember remapped keys (but it turns out this doesn't work,
    # # cause session dies on sign_out!)
    # puts("Session remapped keys is #{session[:remapped_keys]}")
    # session[:remapped_keys] ||= {}
  end
  def new_current_user
    user = User.new
    # Record where this user initially came from:
    user.referer = user.page_views.first.referer if user.page_views.count > 0
    if user.save
      puts("Signing into the stubby.  Curr=#{current_user}")
      set_current_user(user)
      puts("Signed into stubby.  Curr=#{current_user}")
    else
      raise 'Error making stub account. Yikes!'
    end
  end

  def set_current_user(user)
    ## TODO: delete the existing current user if there's nothing
    ## important in it

    puts("Setting current user to #{user.id}")
    session[:current_user_id2] = user.id
    Thread.current[:current_user_id2] = user.id
    Thread.current[:current_user2]    = user
  end

  def affected_objects
    # Right now this works for points, opinions, proposals, and the
    # current opinion's proposal if the current opinion is dirty.
    response = []

    dirtied_keys = Thread.current[:dirtied_keys].keys

    # Grab dirtied points, opinions, and users
    for type in [Point, Opinion, User]
      response.concat(dirtied_keys.select{|k| k.match("/#{type.name.downcase}/")} \
            .map {|k| type.find(key_id(k)).as_json })
    end

    # Grab dirtied proposals
    response.concat(dirtied_keys.select{|k| k.match("/proposal/")} \
            .map {|k| Proposal.find(key_id(k)).proposal_data(current_user)})

    # Output dirty current_user
    if (Thread.current[:dirtied_keys].has_key? '/current_user' \
        or Thread.current[:dirtied_keys].has_key? "/user/#{current_user.id}")
      response.append current_user.current_user_hash(form_authenticity_token) 
    end
    
    return response
  end

  def store_location(path)
    session[:return_to] = path
  end

  def pageview
    if request.method == 'GET' && request.fullpath.index('/users/auth').nil?
      begin
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

        PageView.create! ActionController::Parameters.new(params).permit!
      rescue 
        logger.info 'Could not create PageView'
      end
    end
  end

end
