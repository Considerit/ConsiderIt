class HomeController < ApplicationController
  #caches_page :index
  
  def index
    @user = current_user
  end

end
