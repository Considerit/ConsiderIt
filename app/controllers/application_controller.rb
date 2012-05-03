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

    Account.find_by_identifier(rq.session[:user_theme])
  end

private

  def get_current_tenant(rq = nil)
    rq ||= request
    current_account = Account.find_by_identifier(rq.subdomain)
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
    current_user && current_user.admin
  end

  def current_admin_user
    current_user
  end

end
