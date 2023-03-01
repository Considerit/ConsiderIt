
NOTIFICATION_LAG = 15.minutes

def send_digest(subdomain, user, subscription_settings, deliver = true, since = nil, force = false)
  send_emails = subscription_settings['send_emails']

  subdomain.digest_triggered_for ||= {}

  if subdomain.digest_triggered_for["#{user.id}"] == true  # lazy migration, can be removed after, say, 10/22
    subdomain.digest_triggered_for["#{user.id}"] = (Time.current - 20.minutes).iso8601(3)
  end

  if force && !subdomain.digest_triggered_for["#{user.id}"] # just used for testing in the /rails/mailers previews
    subdomain.digest_triggered_for["#{user.id}"] = (Time.current - 20.minutes).iso8601(3)
  end

  triggered_at = subdomain.digest_triggered_for["#{user.id}"]

  return if !send_emails || \
            (!force && !due_for_notification(user, subdomain)) || \
            (!triggered_at || Time.current - Time.iso8601(triggered_at) < NOTIFICATION_LAG) || \
            (subdomain.customization_json['email_notifications_disabled'] && (!user.super_admin || subdomain.name != 'galacticfederation'))

  last_digest_sent_at = last_sent_at(user, subdomain)
  if !since 
    if last_digest_sent_at
      since = last_digest_sent_at
    else 
      since = user.created_at.to_s
    end
  end

  new_activity = get_new_activity(subdomain, user, since.to_s)

  has_activity_to_report = false 
  new_activity.each do |k,v|
    has_activity_to_report ||= v.count > 0
  end 

  return if !has_activity_to_report && !force

  mail = DigestMailer.digest(subdomain, user, new_activity, last_digest_sent_at, send_emails)

  subdomain.digest_triggered_for["#{user.id}"] = false
  subdomain.save

  pp "delivering to #{user.name}"  
  mail.deliver_now if deliver

  send_key = "/subdomain/#{subdomain.id}"
  user.sent_email_about(send_key)

  mail 

end



def get_new_activity(subdomain, user, since)

  start_period = Time.parse(since).utc - NOTIFICATION_LAG
  end_period   = Time.current.utc - NOTIFICATION_LAG



  pp "#{since}: <#{start_period}, #{end_period}>"
  new_proposals = {}
  subdomain.proposals.where("created_at > '#{start_period}' AND created_at < '#{end_period}'").each do |proposal|
    if proposal.user && proposal.opinions.published.where(:user_id => user.id).count == 0 
      new_proposals[proposal.id] = proposal 
    end 
  end 

  new_points   = subdomain.points.published.named.where("created_at > '#{start_period}' AND created_at < '#{end_period}' AND user_id != #{user.id} AND last_inclusion != -1")
  new_opinions = subdomain.opinions.published.where("created_at > '#{start_period}' AND created_at < '#{end_period}' AND user_id != #{user.id}")
  new_comments = subdomain.comments.where("created_at > '#{start_period}' AND created_at < '#{end_period}' AND user_id != #{user.id}")

  your_proposals = {}
  active_proposals = {}
  new_points.each do |pnt|
    proposal = pnt.proposal
    next if new_proposals.key?(proposal.id) || !proposal.user

    proposal_dict = proposal.user_id == user.id ? your_proposals : active_proposals
    if !proposal_dict.has_key? proposal.id 
      proposal_dict[proposal.id] = {
        :obj => proposal,
        :events => {},
        :relationship => user.opinions.published.where(:proposal_id => proposal.id).count > 0 ? 'You gave an opinion' : false 
      }
    end

    key = "new_point_#{pnt.id}"
    proposal_dict[proposal.id][:events][key] = {
      :obj => pnt,
      :type => 'new_point',
      :users => [pnt.user]
    }
  end 

  new_comments.each do |comment|
    pnt = comment.point
    proposal = pnt.proposal
    next if new_proposals.key?(proposal.id) || !proposal.user
    proposal_dict = proposal.user_id == user.id ? your_proposals : active_proposals
    if !proposal_dict.has_key?(proposal.id)
      proposal_dict[proposal.id] = {
        :obj => proposal,
        :events => {},
        :relationship => user.opinions.published.where(:proposal_id => proposal.id).count > 0 ? 'You gave an opinion' : false 
      }
    end

    key = "new_comment_#{pnt.id}"
    if !proposal_dict[proposal.id][:events].has_key? key 
      if pnt.user_id == user.id
        relationship = 'Your point'
      elsif user.comments.where(:point_id => pnt.id).count > 0 
        relationship = 'You commented on this point'
      else 
        relationship = false
      end
      proposal_dict[proposal.id][:events][key] = {
        :obj => pnt,
        :type => 'new_comment',
        :users => [comment.user],
        :relationship => relationship
      }
    else 
      proposal_dict[proposal.id][:events][key][:users].append comment.user
    end 

  end 

  new_opinions.each do |opinion|
    proposal = opinion.proposal
    next if new_proposals.key?(proposal.id) || !proposal.user

    proposal_dict = proposal.user_id == user.id ? your_proposals : active_proposals
    if !proposal_dict.has_key?(proposal.id)
      proposal_dict[proposal.id] = {
        :obj => proposal,
        :events => {},
        :relationship => user.opinions.published.where(:proposal_id => proposal.id).count > 0 ? 'You gave an opinion' : false 
      }
    end

    if !proposal_dict[proposal.id][:events].has_key? 'new_opinion' 
      proposal_dict[proposal.id][:events]['new_opinion'] = {
        :type => 'new_opinion',
        :users => [opinion.user]
      }
    else 
      proposal_dict[proposal.id][:events]['new_opinion'][:users].append opinion.user
    end 
  end 

  user.points.published.where(:subdomain_id => subdomain.id).each do |pnt|
    pnt.inclusions.where("created_at > '#{start_period}' AND created_at < '#{end_period}' AND user_id != #{user.id}").each do |inclusion|
      pnt = inclusion.point
      proposal = pnt.proposal
      next if !proposal.user || new_proposals.key?(proposal.id) || proposal.opinions.published.where(:user_id => inclusion.user_id).count == 0

      proposal_dict = proposal.user_id == user.id ? your_proposals : active_proposals
      if !proposal_dict.has_key?(proposal.id)
        proposal_dict[proposal.id] = {
          :obj => proposal,
          :events => {},
          :relationship => user.opinions.published.where(:proposal_id => proposal.id).count > 0 ? 'You gave an opinion' : false 
        }
      end

      key = "new_inclusion_#{pnt.id}"
      if !proposal_dict[proposal.id][:events].has_key? key 
        if pnt.user_id == user.id
          relationship = 'Your point'
        elsif user.comments.where(:point_id => pnt.id).count > 0 
          relationship = 'You commented on this point'
        elsif user.inclusions.where(:point_id => pnt.id).count > 0 
          relationship = 'You agreed with this point'
        else 
          relationship = false 
        end
        proposal_dict[proposal.id][:events][key] = {
          :obj => pnt,
          :type => 'new_inclusion',
          :users => [inclusion.user],
          :relationship => relationship
        }
      else 
        proposal_dict[proposal.id][:events][key][:users].append inclusion.user
      end 

    end 
  end

  active = active_proposals.values()
  your = your_proposals.values()

  [active, your].each do |arr|
    arr.sort_by! do |p|
      tot = 0
      p[:events].values.each do |e|
        tot += e[:users].length 
      end 
      tot *= 10 if p.key?(:relationship) && p[:relationship]
      -tot
    end
  end 

  new_proposals = new_proposals.values()
  new_proposals.sort_by! {|p| -p.opinions.published.count }

  return {
    :new_proposals => new_proposals,
    :active_proposals => active,
    :your_proposals => your
  }


end

def due_for_notification(user, subdomain)
  ####
  # Respect the user's notification settings. Compare with time since we last
  # sent them a similar digest email.
  can_send = true

  last_digest_sent_at = last_sent_at(user, subdomain)

  if last_digest_sent_at
    sec_since_last = Time.now() - Time.parse(last_digest_sent_at)
    interval = email_me_no_more_than user.subscription_settings(subdomain)['send_emails']
    can_send = sec_since_last >= interval
  end

  can_send
end

def last_sent_at(user, subdomain)
  send_key = "/subdomain/#{subdomain.id}"
  last_digest_sent_at = user.emails_received[send_key]
  last_digest_sent_at
end


# How long (in seconds) to wait between emails
def email_me_no_more_than(interval)
  # interval is in the format {num}_{seconds|minutes|hours|days}
  num, unit = interval.split('_')

  case unit
  when 'minute'
    multiplier = 60
  when 'hour'
    multiplier = 60 * 60
  when 'day'
    multiplier = 24 * 60 * 60
  when 'week'
    multiplier = 7 * 24 * 60 * 60
  when 'month'
    multiplier = 30 * 24 * 60 * 60      
  else
    raise "#{unit} (#{interval}) is not a supported unit for digests"
  end

   multiplier / num.to_i
end

