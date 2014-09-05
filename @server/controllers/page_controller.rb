class PageController < ApplicationController
  respond_to :json
  def show

    case params[:id]

    when 'homepage'

      result = {
        :proposal_summaries => current_tenant.proposals.open_to_public.browsable.map {|proposal| proposal.proposal_summary()}
      }

    else

      proposal = Proposal.find_by_long_id(params[:id])
      if !proposal or cannot?(:read, proposal)
        # TODO: return with a good HTML code for this case
        render :json => {:result => 'Permission denied'}
        return
      end

      result = proposal.full_data(can?(:manage, proposal))

    end

    result['customer'] = current_tenant
    result['key'] = "/page/#{params[:id]}"
    render :json => result
  end
end
