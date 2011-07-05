class ApplicationController < ActionController::Base
  protect_from_forgery
  theme :theme_resolver
  
private
  def theme_resolver
    if !session.has_key?('user_theme')
      session["user_theme"] = APP_CONFIG['theme']
    end
    session["user_theme"]
  end
end
