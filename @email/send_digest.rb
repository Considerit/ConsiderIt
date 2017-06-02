# wait at least 5 min before sending any notification
BUFFER = 5 * 60 

def send_digest(subdomain, user, notifications, subscription_settings, deliver = true, since = nil)
  
  send_emails = subscription_settings['send_emails']

  return if !send_emails || \
            !due_for_notification(user, subdomain) || \
            !valid_triggering_event(notifications, subscription_settings) || \
            subdomain.name == 'galacticfederation'

  # Hack!! this notification system is terrible, so I'm going to add even more entropy.
  # I'm going to get all the data across the subdomain since the last time a digest 
  # was sent, and not rely on the notification objects. Sorry future Travis!

  last_digest_sent_at = last_sent_at(user, subdomain)
  if !since 
    if last_digest_sent_at
      since = last_digest_sent_at
    else 
      since = user.created_at
    end
  end 

  send_key = "/subdomain/#{subdomain.id}"
  user.sent_email_about(send_key)

  mail = DigestMailer.digest(subdomain, user, notifications, get_new_activity(subdomain, user, since), last_digest_sent_at, send_emails)

  # record that we've sent these notifications
  Notification.transaction do 
    for v in notifications.values
      for vv in v.values
        for vvv in vv.values
          for n in vvv      
            n.sent_email = true
            n.save
          end
        end
      end
    end
  end

  mail.deliver_now if deliver

  mail 

end

####
# Check notifications to determine if a valid triggering event occurred

def valid_triggering_event(notifications, subscription_settings)
  for digest_type, digest_types in notifications
    for digest_id, digest_ids in digest_types
      for event, ns in digest_ids

        for notification in ns

          event_relation = notification.event_object_relationship 

          if subscription_settings.key? "#{event}:#{event_relation}"
            key = "#{event}:#{event_relation}"
          else 
            key = event
          end

          if !subscription_settings[key]
            pp "missing event prefs for #{key}", subscription_settings
            raise "missing event prefs for #{key}"
          end

          if subscription_settings[key] && subscription_settings[key]['email_trigger']

            do_send = !notification.read_at && \
                      Time.now() - notification.created_at > BUFFER
            return true if do_send
          end

        end
      end
    end
  end
  false
end

def get_new_activity(subdomain, user, since)

  new_proposals = {}
  subdomain.proposals.where("created_at > '#{since}'").each do |proposal|
    if proposal.user && proposal.opinions.published.where(:user_id => user.id).count == 0 
      new_proposals[proposal.id] = proposal 
    end 
  end 

  new_points = subdomain.points.published.named.where("created_at > '#{since}' AND user_id != #{user.id} AND last_inclusion != -1")

  new_opinions = subdomain.opinions.published.where("created_at > '#{since}' AND user_id != #{user.id}")
  if subdomain.name == 'engage-cprs'
    new_opinions = new_opinions.where('proposal_id=7382')
  end
  new_comments = subdomain.comments.where("created_at > '#{since}' AND user_id != #{user.id}")

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
    pnt.inclusions.where("created_at > '#{since}' AND user_id != #{user.id}").each do |inclusion|
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

