require 'digest/md5'

class ApplicationController < ActionController::Base
  #protect_from_forgery
  set_current_tenant_through_filter
  prepend_before_action :get_current_tenant

  before_action :init_thread_globals
  after_action  :pageview

  def render(*args)
    return if !current_tenant

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

    # if there are dirtied keys, we'll append the corresponding data to the response
    if Thread.current[:dirtied_keys].keys.length > 0
      for arg in args
        if arg.is_a?(::Hash) && arg.has_key?(:json)
          if arg[:json].is_a?(::Hash)
            # This constraint is not principled, just how it works right now
            raise "JSON response must be an array if there are dirty objects"
          else 
            arg[:json] += compile_dirty_objects()
          end
        end
      end
    end

    super

  end

  def current_ability
    @current_ability ||= Ability.new(current_user, current_tenant, request.session_options[:id], session, params)
  end

  def mail_options
    {:host => request.host,
     :host_with_port => request.host_with_port,
     :from => current_tenant && current_tenant.contact_email && current_tenant.contact_email.length > 0 ? current_tenant.contact_email : APP_CONFIG[:email],
     :app_title => current_tenant ? current_tenant.app_title : '',
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

  def get_current_tenant
    rq = request
    current_account = rq.subdomain.nil? || rq.subdomain.length == 0 ? Account.find(1) : Account.find_by_identifier(rq.subdomain)

    set_current_tenant(current_account) if current_account
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

  def compile_dirty_objects
    # Right now this works for points, opinions, proposals, and the
    # current opinion's proposal if the current opinion is dirty.

    response = []

    # Include the user object too, if we haven't already when fetching /current_user
    if Thread.current[:dirtied_keys].has_key?('/current_user') && !Thread.current[:dirtied_keys].has_key?("/user/#{current_user.id}")
      dirty_key "/user/#{current_user.id}"
    end

    dirtied_keys = Thread.current[:dirtied_keys].keys
    for key in Thread.current[:dirtied_keys].keys

      # Grab dirtied points, opinions, and users
      for type in [Point, Opinion, User]
        if key.match "/#{type.name.downcase}/"
          response.append type.find(key_id(key)).as_json
          next
        end
      end

      # Grab dirtied proposals
      if key.match "/proposal/"
        id = key[10..key.length]
        proposal = Proposal.find_by_id(id) || Proposal.find_by_long_id(id)
        response.append proposal.proposal_data

      elsif key == '/customer'
        response.append current_tenant.as_json

      elsif key == '/current_user'
        response.append current_user.current_user_hash(form_authenticity_token)

      elsif key == '/proposals'
        response.append Proposal.summaries

      elsif key.match '/page/homepage'
        recent_contributors = ActiveRecord::Base.connection.select( "SELECT DISTINCT(u.id) FROM users as u, opinions WHERE u.account_id=#{current_tenant.id} AND u.registration_complete=true AND opinions.user_id = u.id AND opinions.created_at > '#{9.months.ago.to_date}'")      

        clean = {
          users: get_all_user_data(),
          contributors: recent_contributors.map {|u| "/user/#{u['id']}"},
          your_opinions: current_user.opinions.map {|o| o.as_json},
          key: key
        } 
        response.append clean

      elsif key.match "/page/"
        # default to proposal 
        long_id = key[6..key.length]
        proposal = Proposal.find_by_long_id long_id

        clean = { 
          proposal: proposal.proposal_data(),
          users: get_all_user_data(),
          your_opinions: current_user.opinions.map {|o| o.as_json},
          key: key
        }

        if current_tenant.assessment_enabled
          clean.update({
            :assessments => proposal.assessments.completed.public_fields,
            :claims => proposal.assessments.completed.map {|a| a.claims.public_fields}.compact.flatten,
            :verdicts => jsonify_objects(Assessable::Verdict.all, 'verdict')
          })
        end

        response.append clean

      end
    end

    return response
  end

  def get_all_user_data
    users = ActiveRecord::Base.connection.select( "SELECT id,name,avatar_file_name FROM users WHERE account_id=#{current_tenant.id} AND (registration_complete=true OR id=#{current_user.id})")
    users = users.as_json
    jsonify_objects(users, 'user')
  end

  def store_location(path)
    session[:return_to] = path
  end

  def pageview
    if current_tenant && request.method == 'GET' && request.fullpath.index('/auth').nil?
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
