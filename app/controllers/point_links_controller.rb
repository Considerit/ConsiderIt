class PointLinksController < ApplicationController
  def create
    @proposal = Proposal.find(params[:proposal_id])

    params[:point_link][:proposal_id] = @proposal.id
    @point_link = PointLink.new(params[:point_link])

    respond_with(@proposal, @point_link) do |format|
      format.js {
        render :partial => 'point_links/show'
      }
    end
  end
end
