class ApplicationController < ActionController::Base
  #protect_from_forgery
  theme :theme_resolver

  def render(*args)
    #@theme = theme_resolver
    if args
      args.first[:layout] = false if request.xhr? and args.first[:layout].nil?
    end
    @domain = session.has_key?(:domain) ? Domain.find(session[:domain]) : nil
    super
  end
    
private
  def theme_resolver

    if !session.has_key?('user_theme')
      session["user_theme"] = APP_CONFIG['theme']
    end
    session["user_theme"]
  end

  def store_location(path)
    session[:return_to] = path
  end

end
