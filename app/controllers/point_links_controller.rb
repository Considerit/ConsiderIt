class PointLinksController < ApplicationController
  def create
    @option = Option.find(params[:option_id])

    pp params
    params[:point_link][:option_id] = @option.id
    @point_link = PointLink.new(params[:point_link])

    respond_with(@option, @point_link) do |format|
      format.js {
        render :partial => 'point_links/show'
      }
    end
  end
end
