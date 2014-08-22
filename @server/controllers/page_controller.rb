class PageController < ApplicationController
  respond_to :json
  def show
    proposal = Proposal.find_by_long_id(params[:id])
    return if !proposal or cannot?(:read, proposal)

    # if !session.has_key?(proposal.id)
    #   ApplicationController.reset_user_activities(session, proposal)
    # end

    result = proposal.full_data(current_user,
                                can?(:manage, proposal))

    result['customer'] = current_tenant

    result['key'] = "/page/#{params[:id]}"
    render :json => result
  end
end
