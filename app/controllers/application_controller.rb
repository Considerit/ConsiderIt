class ApplicationController < ActionController::Base
  protect_from_forgery
  theme :theme_resolver
  
private
  def theme_resolver
    "lvg"
    "default"
  end
end
