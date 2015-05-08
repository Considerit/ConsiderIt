class DigestPreview < ActionMailer::Preview
  def proposal

    proposal_aggregation = Notifier.aggregate_by_proposal
      
    user_id = proposal_aggregation.keys.sample
    pp proposal_aggregation[user_id].keys
    channel = proposal_aggregation[user_id].keys.sample
    proposal_id = proposal_aggregation[user_id][channel].keys.sample

    notifications = proposal_aggregation[user_id][channel][proposal_id]
    proposal = Proposal.find(proposal_id)
    user = User.find(user_id)
    DigestMailer.proposal(proposal, user, notifications, channel)

  end

end