class PageController < ApplicationController
  respond_to :json

  def show
    case params[:id]

    when 'homepage'
      key = '/page/homepage'
      dirty_key key

    when 'about' # don't need anything special
      key = '/page/about'

    when 'proposal/new' # don't need anything special
      key = '/page/proposal/new'

    else # if proposal

      proposal = Proposal.find_by_long_id(params[:id])
      if !proposal 
        render :status => :not_found, :json => {:result => 'Not found'}
        return
      elsif cannot?(:read, proposal)
        render :status => :forbidden, :json => {:result => 'Permission denied'}
        return
      end

      key = "/page/#{proposal.long_id}"
      dirty_key key
    end


    render :json => []

  end

end
