class Dashboard::UsersController < Dashboard::DashboardController
  def show
    # only output data regarding publicly available data
    # TODO: include data from non-public proposals if current user has permission
    # TODO: filter data output to fields only strictly necessary - lots of redundant data here

    user = User.find(params[:id])

    referenced_proposals = {}
    positions = []
    user.positions.published.each do |position|
      if !referenced_proposals.has_key?(position.proposal_id)
        proposal = Proposal.find(position.proposal_id) 
        if proposal.public? # or user has access ...
          referenced_proposals[position.proposal_id] = proposal
          positions.push user.positions.where(:proposal_id => position.proposal_id).published.public_fields.last
        end
      end
    end

    referenced_points = {}
    user.points.published.each do |pnt|
      proposal = Proposal.find(pnt.proposal_id) 
      if proposal.public? # or user has access...
        referenced_points[pnt.id] = pnt
        if !referenced_proposals.has_key?(pnt.proposal_id)
          referenced_proposals[pnt.proposal_id] = proposal
        end
      end
    end

    user.comments.each do |comment|      
      if !referenced_points.has_key? comment.commentable_id
        pnt = comment.root_object
        proposal = Proposal.find(pnt.proposal_id) 

        if pnt.published && proposal.public? # or user has access ...
          referenced_points[pnt.id] = pnt

          if !referenced_proposals.has_key? pnt.proposal_id
            referenced_proposals[pnt.proposal_id] = proposal
          end
        end
      end
    end

    data = {
      :user_id => user.id,
      :proposals => user.proposals.public.public_fields,
      :referenced_proposals => referenced_proposals,
      :referenced_points => referenced_points,
      :positions => positions,
      :points => user.points.published.public_fields,
      :comments => user.comments.public_fields
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