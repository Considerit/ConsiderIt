class HistogramController < ApplicationController
  respond_to :json

  def show
    # Todo:
    #  - Implment the cache
    #  - Move this to application_controller so dirty_key works
    #  - Dirty it when opinions are added or changed

    width = params[:width]
    height = params[:height]
    group_filter = params[:group]

    if false                    # look in cache
      
    else                        # recompute and cache
      opinions = Proposal.find(params[:id]).opinions
      if group_filter
        opinions = opinions.find_all {|o|
          o.user && JSON.parse(o.user.groups || '[]').include?(group_filter)
        }
      end
      opinions = opinions.map {|o|
        { 'user' => "/user/#{o.user_id}",
          'stance' => o.stance }}
    end

    render :json => { 'key' => "/histogram/#{params[:id]}",
                      'opinions' => opinions
                    }
  end

  def update
    # Todo:
    #  - Implement this method to store in cache
    #  - Add code on client to save it when simulation has finished
    #  - Add security rules so people can't cheat it
    proposal = Proposal.find params[:id]

    dirty_key "/proposal/#{proposal.id}"
    render :json => []
  end

end
