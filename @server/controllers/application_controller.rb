require 'digest/md5'

class ApplicationController < ActionController::Base
  #protect_from_forgery
  set_current_tenant_through_filter
  prepend_before_action :get_current_tenant

  before_action :init_thread_globals
  after_action  :pageview

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


    if current_tenant.host.nil?
      current_tenant.host = request.host
      current_tenant.host_with_port = request.host_with_port
      current_tenant.save
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

private

  def get_current_tenant(rq = nil)
    rq ||= request
    current_account = rq.subdomain.nil? || rq.subdomain.length == 0 ? Account.find(1) : Account.find_by_identifier(rq.subdomain)

    current_account = Account.find(1) if current_account.nil?
    
    set_current_tenant(current_account)
    session["user_account_identifier"] = current_tenant.identifier
    current_account
  end

  def init_thread_globals
    # Make things to remember changes
    Thread.current[:dirtied_keys] = {}
    Thread.current[:tenant] = current_tenant
    Thread.current[:mail_options] = mail_options

    puts("In before: is there a current user? '#{session[:current_user_id2]}'")
    # First, reset the thread's current_user values from the session
    Thread.current[:current_user_id2] = session[:current_user_id2]
    Thread.current[:current_user2] = nil
    # Now let's see if they work
    if !current_user()
      # If not, let's make a new one, which will replace the old
      # values in the session and thread
      puts("That current_user '#{session[:current_user_id2]}' is bad. Making a new one.")
      new_current_user
    end

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
    user
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
            .map {|k| Proposal.find(key_id(k)).proposal_data()})

    # Output dirty current_user
    if Thread.current[:dirtied_keys].has_key? '/current_user'
      response.append current_user.current_user_hash(form_authenticity_token)

      # And include the user object too, if we haven't already
      if not Thread.current[:dirtied_keys].has_key?("/user/#{current_user.id}")
        response.append(User.find(current_user.id).as_json)
      end
    end

    # Handle dirty proposals key, which are all the summaries of active proposals 
    # the current user can access
    if Thread.current[:dirtied_keys].has_key? '/proposals'
      response.append Proposal.summaries
    end

    if Thread.current[:dirtied_keys].has_key? '/page/homepage'
      response.append PageController.homepage_data()
    end
    return response
  end

  def store_location(path)
    session[:return_to] = path
  end

  def pageview
    if request.method == 'GET' && request.fullpath.index('/auth').nil?
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
