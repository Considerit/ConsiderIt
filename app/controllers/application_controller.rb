require 'digest/md5'

class ApplicationController < ActionController::Base
  #protect_from_forgery
  set_current_tenant_through_filter
  prepend_before_filter :get_current_tenant
  before_filter :theme_resolver

  def render(*args)
    if !session.has_key?(:referer)
      session[:referer] = request.referer      
    end

    #TODO: what does this do?
    if args && args.first.respond_to?('has_key?')
      args.first[:layout] = false if request.xhr? and args.first[:layout].nil?
    else
      args.append({:layout => false}) if request.xhr?
    end

    #@domain = session.has_key?(:domain) ? session[:domain] : nil
    #@current_page = request.fullpath == '/' ? 'homepage' : ''

    if current_tenant.host.nil?
      current_tenant.host = request.host
      current_tenant.host_with_port = request.host_with_port
      current_tenant.save
    end

    @host_with_port = request.host_with_port

    # Destroy the current user if a request is made to the server when the user has yet
    # to complete their registration. There are no legit reasons for a refresh to occur, 
    # and many illegimate ones. 
    if !request.env.has_key?("omniauth.auth") && !request.xhr? && current_user && !current_user.registration_complete
      user = current_user
      Devise.sign_out_all_scopes ? sign_out : sign_out('user')
      user.destroy
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
    @current_ability ||= Ability.new(current_user, request.session_options[:id], params)
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
    current_account = Account.find_by_identifier(rq.subdomain)

    if current_account.nil?
      current_account = Account.find(1)
    end    

    set_current_tenant(current_account)
    session["user_account_identifier"] = current_tenant.identifier
    current_account
  end

  def theme_resolver
    if !session.has_key?('user_theme')
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

  def authenticate_admin_user!
    if ! (current_user && current_user.is_admin?)
      #raise 'YOU DO NOT HAVE ADMIN PRIVILEGES'
      redirect_to root_path
      return false
    end
    true
  end

  def current_admin_user
    current_user
  end

end
