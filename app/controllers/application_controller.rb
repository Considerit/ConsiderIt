class ApplicationController < ActionController::Base
  #protect_from_forgery
  set_current_tenant_through_filter
  before_filter :get_current_tenant

  #theme :theme_resolver
  before_filter :theme_resolver

  def render(*args)
    if args && args.first.respond_to?('has_key?')
      args.first[:layout] = false if request.xhr? and args.first[:layout].nil?
    else
      args.append({:layout => false}) if request.xhr?
    end
    @domain = session.has_key?(:domain) ? Domain.find(session[:domain]) : nil
    @theme = current_tenant.theme
    super
  end

  def self.find_current_tenant(rq)
    tenant = Account.find_by_identifier(rq.session[:user_theme])
    if tenant.nil?
      tenant = Account.find(7)
    end
    tenant
  end

  def default_url_options
    
    {:host => request.host_with_port,
     :from => current_tenant.contact_email,
     :app_title => current_tenant.app_title
    }
  end

private

  def get_current_tenant(rq = nil)
    rq ||= request
    current_account = Account.find_by_identifier(rq.subdomain)
    if current_account.nil?
      current_account = Account.find(7)
    end    
    set_current_tenant(current_account)
    current_account
  end

  def theme_resolver
    if !session.has_key?('user_theme') || Rails.env == 'development'
      session["user_theme"] = current_tenant.theme
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
