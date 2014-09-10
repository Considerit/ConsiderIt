class PageController < ApplicationController
  respond_to :json
  def show

    case params[:id]

    when 'homepage'
      result = get_proposal_summaries()
      result['users'] = get_all_user_data()

    else # if proposal

      proposal = Proposal.find_by_long_id(params[:id])
      if !proposal or cannot?(:read, proposal)
        # TODO: return an appropriate HTML code for this case
        render :json => {:result => 'Permission denied'}
        return
      end

      result = proposal.full_data(can?(:manage, proposal))
      result.update(get_proposal_summaries())
      result['users'] = get_all_user_data()

    end

    result['customer'] = current_tenant
    result['key'] = "/page/#{params[:id]}"
    render :json => result
  end

  private

  # TODO: Not satisfied with this code. How should these requests be filled? 
  #       proposal.full_data returns proposal data that is also 
  #       included in get_proposal_summaries. It also returns your_opinion, which is returned in
  #       your_opinions _if_ it is already published.
  def get_all_user_data
    users = ActiveRecord::Base.connection.select( "SELECT id,name,avatar_file_name FROM users WHERE account_id=#{current_tenant.id} AND (registration_complete=true OR id=#{current_user.id})")
    users = users.as_json
    jsonify_objects(users, 'user')
  end

  def get_proposal_summaries
    clustered_proposals = {}

    current_tenant.proposals.open_to_public.browsable.where('cluster IS NOT NULL').each do |proposal|        
      clustered_proposals[proposal.cluster] = [] if !clustered_proposals.has_key? proposal.cluster
      clustered_proposals[proposal.cluster].append proposal.proposal_summary()
    end

    if current_tenant.identifier == 'livingvotersguide'
      # manual ordering for LVG
      cluster_order = ['Statewide measures', 'Advisory votes'] 
    else
      #TODO: order the group for the general case. Probably sort groups by the most recent Opinion. 
      cluster_order = clustered_proposals.keys()
    end
    proposals = {
      key: 'viewable_proposals',
      clusters: cluster_order.map {|cluster| {:name => cluster, :proposals => clustered_proposals[cluster] }}
    }

    result = {
      :viewable_proposals => proposals,
      :your_opinions => current_user.opinions.published.map {|o| o.as_json}
    }

    result

  end
end
