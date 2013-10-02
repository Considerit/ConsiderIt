class Dashboard::UsersController < Dashboard::DashboardController
  def show
    # only output data regarding publicly available data
    # TODO: filter data output to fields only strictly necessary - lots of redundant data here

    user = User.find(params[:id])

    referenced_proposals = {}
    positions = []
    user.positions.published.each do |position|
      if !referenced_proposals.has_key?(position.proposal_id)
        proposal = Proposal.find(position.proposal_id) 
        if can?(:read, proposal)  
          referenced_proposals[position.proposal_id] = proposal
          positions.push user.positions.where(:proposal_id => position.proposal_id).published.public_fields.last
        end
      end
    end

    referenced_points = {}
    influenced_users = {}
    influenced_users_by_point = {}
    accessible_points = []

    user.points.published.named.each do |pnt|
      proposal = Proposal.find(pnt.proposal_id) 
      if can?(:read, proposal) && (!pnt.hide_name || (current_user && pnt.user_id == current_user.id)) 
        referenced_points[pnt.id] = pnt
        accessible_points.push pnt.id

        influenced_users_by_point[pnt.id] = []
        pnt.inclusions.where("user_id != #{user.id}").each do |inc|
          influenced_users[inc.user_id] = 0 if ! influenced_users.has_key?(inc.user_id)
          influenced_users[inc.user_id] +=1
          influenced_users_by_point[pnt.id].push inc.user_id
        end

        if !referenced_proposals.has_key?(pnt.proposal_id)
          referenced_proposals[pnt.proposal_id] = proposal
        end
      end
    end

    user.comments.each do |comment|      
      if !referenced_points.has_key? comment.commentable_id
        pnt = comment.root_object
        proposal = Proposal.find(pnt.proposal_id) 

        if pnt.published && can?(:read, proposal)
          referenced_points[pnt.id] = pnt

          if !referenced_proposals.has_key? pnt.proposal_id
            referenced_proposals[pnt.proposal_id] = proposal
          end
        end
      end
    end

    data = {
      :user_id => user.id,
      :proposals => user.proposals.open_to_public.public_fields,
      :referenced_proposals => referenced_proposals,
      :referenced_points => referenced_points,
      :positions => positions,
      :points => user.points.published.where("id in (?)", accessible_points).public_fields,
      :comments => user.comments.public_fields,
      :influenced_users => influenced_users,
      :influenced_users_by_point => influenced_users_by_point
    }

    render :json => data
  end

  def edit
    #TODO: authorize for edit profile
  end

  def edit_account
    #TODO: authorize for edit profile
  end

  def edit_notifications
    #TODO: authorize for edit profile
  end


end