namespace :test do

  # example: rake test:send_all_emails[1,6] --trace

  desc "Generate all emails"
  task :send_all_emails, [:account_id, :user_id, :host, :from] => :environment do |t, args|
    if !args[:user_id] || !args[:account_id]
      raise 'supply proper parameters'
    end

    account = Account.find(args[:account_id])
    user = User.find(args[:user_id])

    from = args[:from] || account.contact_email
    host = args[:host] || "#{account.identifier}.testing.dev"
    app_title = account.app_title

    mail_options = {:host => host, :from => from, :app_title => app_title, :current_tenant => account}

    ###### Discussion level ######
    proposal = get_proposal_with_no_opinions(account)
    pp "****************"
    pp "discussion_new_proposal"
    pp "Proposal: #{proposal.id}"
    if proposal
      email = EventMailer.discussion_new_proposal(user, proposal, mail_options, '').deliver!
    end

    ###### Proposal level ######
    proposal = get_proposal_with_opinions(account)
    pp "****************"
    pp "proposal_milestone_reached"
    pp "Proposal: #{proposal.id}"
    if proposal
      email = EventMailer.proposal_milestone_reached(user, proposal, 100, mail_options).deliver!
    end

    notification_types = ['your proposal', 'opinion submitter', 'lurker']
    notification_types.each do |nt|
      proposal = get_proposal_with_points(account)
      next if proposal.nil?

      point = proposal.points.published.sample
      pp "****************"
      pp "new_point"
      pp "Proposal: #{proposal.id}"
      pp "Point: #{point.id}" 
      pp "Notification_type: #{nt}"     
      if proposal && point
        email = EventMailer.new_point(user, point, mail_options, nt).deliver!
      end
    end

    ###### Point level ######
    notification_types = ['your point', 'participant', 'included point', 'lurker']
    notification_types.each do |nt|
      comment = account.comments.sample
      next if comment.nil?

      point = comment.point
      pp "****************"
      pp "new_comment"
      pp "Comment: #{comment.id}"
      pp "Point: #{point.id}"
      pp "Notification_type: #{nt}"
      if comment && point
        email = EventMailer.new_comment(user, point, comment, mail_options, nt).deliver!
      end
    end

    ###### Comment level ######
    # notification_types = ['your comment', 'other summarizer']
    # notification_types.each do |nt|
    #   bullet = account.reflect_bullets.sample
    #   next if bullet.nil?
    #   bullet_rev = bullet.revisions.last

    #   comment = bullet_rev.comment
    #   pp "****************"
    #   pp "reflect_new_bullet"
    #   pp "Comment: #{comment.id}"
    #   pp "Bullet: #{bullet.id}" 
    #   pp "Notification_type: #{nt}"   
    #   if bullet && bullet_rev && comment   
    #     email = EventMailer.reflect_new_bullet(user, bullet_rev, comment, mail_options, nt).deliver!
    #   end
    # end

    # notification_types = ['your bullet', 'other summarizer']
    # notification_types.each do |nt|
    #   response = account.reflect_responses.sample
    #   if response
    #     response_rev = response.revisions.last
    #     bullet = response.bullet
    #     bullet_rev = bullet.revisions.last
    #     comment = bullet_rev.comment

    #     pp "****************"
    #     pp "reflect_new_response"
    #     pp "Comment: #{comment.id}"
    #     pp "Bullet: #{bullet.id}" 
    #     pp "Notification_type: #{nt}"    
    #     if response_rev && bullet && bullet_rev && comment   
    #       email = EventMailer.reflect_new_response(user, response_rev, bullet_rev, comment, mail_options, nt).deliver!
    #     end
    #   end
    # end


  end


  def get_proposal_with_points(account)
    account.points.published.sample.proposal
  end

  def get_proposal_with_no_opinions(account)
    proposal = nil
    i = 0
    until proposal && (proposal.opinions.count == 0 || i > 50)
      proposal = account.proposals.sample
      i += 1
    end
    proposal
  end

  def get_proposal_with_opinions(account)
    account.opinions.published.sample.proposal
  end

end