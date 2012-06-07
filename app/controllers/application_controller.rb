require 'digest/md5'

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
    if current_tenant.host.nil?
      current_tenant.host = request.host
      current_tenant.host_with_port = request.host_with_port
      current_tenant.save
    end

    super
  end

  def self.find_current_tenant(rq)
    tenant = Account.find_by_identifier(rq.session[:user_theme])
    if tenant.nil?
      tenant = Account.find(7)
    end
    tenant
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
