class ThemeController < ApplicationController
  respond_to :html
  
  def set     
    session["user_theme"] = params[:theme]    
    redirect_to request.referer
  end
  
end
