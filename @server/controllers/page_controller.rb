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

    pageview key

    render :json => []

  end

  private 

  def pageview(page)
    begin
      params = {
        :account_id => current_tenant.id,
        :user_id => current_user.id,
        :url => request.fullpath,
        :created_at => Time.current
      }
      PageView.create! ActionController::Parameters.new(params).permit!
    rescue 
      logger.info 'Could not create PageView'
    end
  end

end
