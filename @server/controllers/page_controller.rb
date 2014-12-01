class PageController < ApplicationController
  respond_to :json

  def show
    if params[:id] == 'homepage'
      key = '/page/homepage'
      dirty_key key
      dirty_key '/users'

    elsif params[:id] == 'proposal/new' # don't need anything special
      key = '/page/proposal/new'

    elsif params[:id] == 'about' || params[:id].match('dashboard/') # don't need anything special
      key = "/page/#{params[:id]}"

    else # if proposal

      proposal = Proposal.find_by_slug(params[:id])

      if !proposal 
        render :status => :not_found, :json => {:result => 'Not found'}
        return
      elsif cannot?(:read, proposal)
        render :status => :forbidden, :json => {:result => 'Permission denied'}
        return
      end

      # Ensure an existing opinion for this user
      your_opinion = Opinion.get_or_make(proposal, current_user)

      key = "/page/#{proposal.slug}"
      dirty_key key
      dirty_key '/users'
    end


    render :json => []

  end

end
