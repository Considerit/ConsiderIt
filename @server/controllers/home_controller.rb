
class HomeController < ApplicationController
  caches_action :avatars, :cache_path => proc {|c|
    {:tag => "avatars-#{current_tenant.id}-#{Rails.cache.read("avatar-digest-#{current_tenant.id}")}"}
  }

  def index
    render "layouts/application", :layout => false
  end

  def avatars
    #result = render_to_string :partial => './avatars'
    respond_to do |format|
      format.html { render :partial => './avatars' } 
      format.json { render :partial => './avatars' }
    end
  end

end
