class PageController < ApplicationController
  respond_to :json
  
  def show
    case params[:id]

    when 'homepage'
      dirty_key '/page/homepage'

    when 'about'
      # don't need anything special
    
    else # if proposal

      proposal = Proposal.find_by_long_id(params[:id])
      if !proposal 
        render :status => :not_found, :json => {:result => 'Not found'}
        return
      elsif cannot?(:read, proposal)
        render :status => :forbidden, :json => {:result => 'Permission denied'}
        return
      end

      dirty_key "/page/#{proposal.long_id}"

    end

    render :json => []

  end

end
