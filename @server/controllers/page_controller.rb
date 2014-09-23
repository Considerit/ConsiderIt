class PageController < ApplicationController
  respond_to :json

  def show
    case params[:id]

    when 'homepage'
      key = '/page/homepage'
      dirty_key key

    when 'about'
      # don't need anything special
      key = '/page/about'

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

    if !session[:search_bot]
      Log.create!({
        :account_id => current_tenant.id,
        :who => current_user,
        :what => 'loaded page',
        :where => key[6..key.length],
        :when => Time.current
      })
    end

    render :json => []

  end

end
