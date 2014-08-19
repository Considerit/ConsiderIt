
class HomeController < ApplicationController
  caches_action :avatars, :cache_path => proc {|c|
    {:tag => "avatars-#{current_tenant.id}-#{Rails.cache.read("avatar-digest-#{current_tenant.id}")}"}
  }

  def index
    # We don't have a homepage. In the iterim, let's just redirect 
    # accesses to the homepage to the latest published proposal
    if request.path == '/'
      proposal = current_tenant.proposals.open_to_public.active.last
      redirect_to "/#{proposal.long_id}"
      return
    end

    render "layouts/application", :layout => false
  end

  def activemike
    render "layouts/testmike", :layout => false
  end

  def avatars
    #result = render_to_string :partial => './avatars'
    respond_to do |format|
      format.html { render :partial => './avatars' } 
      format.json { render :partial => './avatars' }
    end
  end

end
