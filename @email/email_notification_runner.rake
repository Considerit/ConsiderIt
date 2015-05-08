task :send_email_notifications => :environment do

  def proposal_digest(channel, user_id, proposal_id, notifications)
    triggering_events = ['new_point', 'new_comment']

    proposal = Proposal.find(proposal_id)
    key = "/proposal/#{proposal.id}"

    user = User.find(user_id)

    emails_sent = user.emails_received
    emails_sent[channel] ||= {}

    #  Check if there is a valid triggering event that
    #  has occurred at least T since last triggering event
    #  where T is the preference set by user
    can_send = true
    last_digest_sent_at = emails_sent[channel][key]

    if last_digest_sent_at
      sec_since_last = Time.now() - Time.parse(last_digest_sent_at)
      email_me_no_more_than = User.digest_interval_for channel, proposal
      can_send = sec_since_last >= email_me_no_more_than
    end


    if can_send
      DigestMailer.proposal(proposal, user, notifications, channel)
      emails_sent[channel][key] = Time.now().to_s
      user.save
    end

  end

  proposal_aggregation = Notifier.aggregate_by_proposal

  for user_id in proposal_aggregation.keys
    for channel in proposal_aggregation[user_id]
      for proposal_id in proposal_aggregation[user_id][channel]
        proposal_digest(channel, user_id, proposal_id, proposal_aggregation[user_id][channel][proposal_id])
      end
    end
  end




  #   # AdminMailer.content_to_assess(assessment, user, subdomain).deliver_now
  # end

end
