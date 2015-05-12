
require 'digest/md5'
require 'exception_notifier'
require Rails.root.join('@server', 'permissions')

class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  skip_before_action :verify_authenticity_token, if: :csrf_skippable?

  set_current_tenant_through_filter
  prepend_before_action :get_current_subdomain
  before_action :init_thread_globals

  rescue_from PermissionDenied do |exception|
    result = { :permission_denied => exception.reason } 
    result[:key] = exception.key if exception.key
    render :json => result
  end

  def application
    dirty_key '/application'
    render :json => []
  end

  def app_index
    render :json => [{
      :key => '/apps',
      :apps => ['franklin', 'product_page']
    }]
  end

  def render(*args)

    dirty_key '/application'

    # if there are dirtied keys, we'll append the corresponding data to the response
    if current_subdomain && Thread.current[:dirtied_keys].keys.length > 0
      for arg in args
        if arg.is_a?(::Hash) && arg.has_key?(:json)
          if arg[:json].is_a?(::Hash)
            arg[:json] = [arg[:json]]
          end
          arg[:json] += compile_dirty_objects()
        end
      end
    end

    super

  end

  def authorize!(action, object = nil, key = nil)
    permitted = permit(action, object)
    if permitted < 0
      raise PermissionDenied.new permitted, key
    end
  end

protected
  def csrf_skippable?
    request.format.json? && request.content_type != "text/plain" && (!!request.xml_http_request?)
  end

  def write_to_log(options)
    begin
      Log.create!({
        :subdomain_id => current_subdomain.id,
        :who => current_user.id,
        :what => options[:what],
        :where => options[:where],
        :when => Time.current,
        :details => options.has_key?(:details) ? JSON.dump(options[:details]) : nil
      })
    rescue => e
      ExceptionNotifier.notify_exception(e)      
    end
  end

  def get_current_subdomain
    rq = request

    # when to display a considerit homepage
    can_display_homepage = (Rails.env.production? && rq.host.include?('consider.it')) || session[:app] == 'product_page'
    if (rq.subdomain.nil? || rq.subdomain.length == 0) && can_display_homepage 
      candidate_subdomain = Subdomain.find_by_name('homepage')
    else
      default_subdomain = session.has_key?(:default_subdomain) ? session[:default_subdomain] : 1
      if rq.subdomain.nil? || rq.subdomain.length == 0
        begin
          candidate_subdomain = Subdomain.find(default_subdomain)
        rescue ActiveRecord::RecordNotFound
          candidate_subdomain = Subdomain.find(1)
        end
      else 
        candidate_subdomain = Subdomain.find_by_name(rq.subdomain)
      end
    end

    set_current_tenant(candidate_subdomain) if candidate_subdomain
    current_subdomain
  end

  def init_thread_globals
    # Make things to remember changes
    Thread.current[:dirtied_keys] = {}
    Thread.current[:subdomain] = ActsAsTenant.current_tenant

    # puts("In before: is there a current user? '#{session[:current_user_id]}'")
    # First, reset the thread's current_user values from the session
    Thread.current[:current_user_id] = session[:current_user_id]
    Thread.current[:current_user] = nil
    # Now let's see if they work
    if !current_user()
      # If not, let's make a new one, which will replace the old
      # values in the session and thread
      puts("That current_user '#{session[:current_user_id]}' is bad. Making a new one.")
      new_current_user
    end

    # if [197946, 14897].include?(Thread.current[:current_user_id])
    #   raise PermissionDenied.new('Your account has been disabled until the election is over for violating the Civility Pledge.')
    # end
  end
  
  def new_current_user
    user = User.new
    if user.save
      puts("Signing into the stubby.  Curr=#{current_user}")
      set_current_user(user)
      puts("Signed into stubby.  Curr=#{current_user} #{current_user.id} #{session[:current_user_id]}")
    else
      raise 'Error making stub account. Yikes!'
    end
    user
  end

  def set_current_user(user)
    ## TODO: delete the existing current user if there's nothing
    ##       important in it

    puts("Setting current user to #{user.id}")
    session[:current_user_id] = user.id
    Thread.current[:current_user_id] = user.id
    Thread.current[:current_user]    = user
  end

  def replace_user(old_user, new_user)
    return if old_user.id == new_user.id
    if old_user.registered then raise "Replacing a real user! Danger!" end

    new_user.absorb(old_user)

    # puts("Deleting old user #{old_user.id}")
    old_user.destroy()

    # puts("Done replacing. current_user=#{current_user}")
  end
  
  def compile_dirty_objects
    response = []
    processed = {}

    # Include the user object too, if we haven't already when fetching /current_user
    if Thread.current[:dirtied_keys].has_key?('/current_user') && !Thread.current[:dirtied_keys].has_key?("/user/#{current_user.id}")
      dirty_key "/user/#{current_user.id}"
    end

    while Thread.current[:dirtied_keys].keys.length > 0

      key = Thread.current[:dirtied_keys].keys[0]
      Thread.current[:dirtied_keys].delete key

      next if processed.has_key?(key)
      processed[key] = 1

      # Grab dirtied points, opinions, and users
      for type in [Point, Opinion, User, Comment, Moderation]
        if key.match "/#{type.name.downcase}/"
          response.append type.find(key_id(key)).as_json
          next
        end
      end

      if key.match "/proposal/"
        id = key[10..key.length]
        proposal = Proposal.find_by_id(id) || Proposal.find_by_slug(id)
        response.append proposal.as_json  #proposal_data

      elsif key.match "/comments/"
        point = Point.find(key[10..key.length])
        response.append Comment.comments_for_point(point)
      
      elsif key == '/application'
        response.append({
          key: '/application',
          app: session[:app],
          dev: (Rails.env.development? || request.host.end_with?('chlk.it')),
          asset_host: "#{Rails.application.config.action_controller.asset_host}",
          godmode: session[:godmode]
        })
      elsif key == '/subdomain'
        response.append current_subdomain.as_json

      elsif key == '/current_user'
        response.append current_user.current_user_hash(form_authenticity_token)

      elsif key == '/proposals'
        response.append Proposal.summaries

      elsif key == '/users'
        response.append User.all_for_subdomain

      elsif key == '/page/'
        recent_contributors = ActiveRecord::Base.connection.exec_query( "SELECT DISTINCT(u.id) FROM users as u, opinions WHERE opinions.subdomain_id=#{current_subdomain.id} AND opinions.published=1 AND opinions.user_id = u.id AND opinions.created_at > '#{9.months.ago.to_date}'")      

        clean = {
          contributors: recent_contributors.map {|u| "/user/#{u['id']}"},
          your_opinions: current_user.opinions.map {|o| o.as_json},
          key: key
        } 
        response.append clean

      elsif key == '/page/dashboard/email_notifications'
        response.append({:follows => current_user.notifications, :key => key})

      elsif key == '/page/dashboard/moderate'
        response.append Moderation.all_for_subdomain

      elsif key == '/page/dashboard/assessment'
        response.append Assessment.all_for_subdomain

      elsif key.match "/page/dashboard"
        noop = 1

      elsif key.match "/page/"
        # default to proposal 
        slug = key[6..key.length]
        proposal = Proposal.find_by_slug slug

        if current_subdomain.moderate_points_mode == 1
          moderation_status_check = 'moderation_status=1'
        else 
          moderation_status_check = '(moderation_status IS NULL OR moderation_status=1)'
        end

        pointz = proposal.points.where("(published=1 AND #{moderation_status_check}) OR user_id=#{current_user.id}")
        pointz = pointz.public_fields.map {|p| p.as_json}

        published_opinions = proposal.opinions.published
        ops = published_opinions.public_fields.map {|x| x.as_json}

        if published_opinions.where(:user_id => nil).count > 0
          throw "We have published opinions without a user: #{published_opinions.map {|o| o.id}}"
        end

        clean = { 
          your_opinions: current_user.opinions.map {|o| o.as_json},
          key: key,
          proposal: proposal.as_json,
          points: pointz,
          opinions: ops
        }

        if current_subdomain.assessment_enabled
          clean.update({
            :assessments => proposal.assessments.completed,
            :claims => proposal.assessments.completed.map {|a| a.claims}.compact.flatten,
            :verdicts => Assessable::Verdict.all
          })
        end

        response.append clean
      elsif key.match '/assessment/'
        assessment = Assessment.find(key[12..key.length])
        response.append assessment.as_json
      elsif key.match '/claim/'
        claim = Assessable::Claim.find(key[7..key.length])
        response.append claim.as_json

      elsif key == '/asset_manifest'
        manifest = JSON.parse(File.open("public/assets/rev-manifest.json", "rb") {|io| io.read})
        manifest.key = '/asset_manifest'
        response.append manifest

      end
    end

    return response
  end


  def self.MD5_hexdigest(key)
    Digest::MD5.hexdigest(key)
  end

  #####
  # aliasing current_tenant from acts_as_tenant gem so we can be consistent with subdomain
  # helper_method :current_subdomain
  # def current_subdomain
  #   ActsAsTenant.current_tenant
  # end


  #####
  # Checks to see if we can verify the user's email address.
  # There are two pathways here: 
  #     1) Every route processed by the HTML controller calls this method
  #        to check if there are some url parameters mapping to a user
  #        (as happens via all considerit email links). 
  #         
  #        If the user is currently logged out and the token valid, 
  #        the user will even be logged in. 
  #
  #     2) If the users is manually trying to enter a verification code
  #        the current_user_controller will invoke this method directly. 
  def verify_user(target_email = nil, auth_token = nil)

    # extract query parameters from an email link
    if params.has_key?('u') && params.has_key?('t') && params['t'].length > 0
      target_email = params['u']
      auth_token = params['t']
    end

    if target_email && auth_token

      # Figure out which user is being targetted
      if current_user.registered
        target_user = current_user
      else
        target_user = User.find_by_email target_email
      end

      # Check if the encrypted token is valid for the target user
      if !target_user
        token_valid = false
      else
        encrypted = ApplicationController.MD5_hexdigest("#{target_email}#{target_user.unique_token}#{current_subdomain.name}")    
        token_valid = encrypted == auth_token
      end

      if token_valid 

        # Try to login if the tokens match a valid user
        if current_user.id != target_user.id
          replace_user(current_user, target_user)
          set_current_user(target_user)
          current_user.add_token() # Logging in via email token is dangerous, so we'll only allow it once per token          
        end

        current_user.verified = true
        current_user.save
        dirty_key('/current_user')

        # unsubscribe from this object if that's what they want to do...
        if params.has_key?('unsubscribe_key')
          sub_settings = current_user.subscription_settings(current_subdomain)
          key = params['unsubscribe_key']
          sub_settings[key] = 'none'
          current_user.subscriptions = current_user.update_subscriptions(sub_settings)
          current_user.save
        end

      end
    end
  end

end





