class ApplicationController < ActionController::Base
  #protect_from_forgery
  set_current_tenant_through_filter
  before_filter :get_current_tenant

  theme :theme_resolver

  def render(*args)
    if args && args.first.respond_to?('has_key?')
      args.first[:layout] = false if request.xhr? and args.first[:layout].nil?
    else
      args.append({:layout => false}) if request.xhr?
    end
    @domain = session.has_key?(:domain) ? Domain.find(session[:domain]) : nil
    super
  end
    
private

  def get_current_tenant
    if Account.count > 0
      current_account = Account.find(1)
      set_current_tenant(current_account)
    end
  end

  def theme_resolver
    if !session.has_key?('user_theme')
      session["user_theme"] = APP_CONFIG[:application_name]
    end
    session["user_theme"]
  end

  def store_location(path)
    session[:return_to] = path
  end

end
