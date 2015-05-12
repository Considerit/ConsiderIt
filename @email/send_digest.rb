# wait at least 2 min before sending any notification
BUFFER = 2 * 60 

def send_digest(user, digest_object, notifications, subscription_settings, emails_sent)
  digest = digest_object.class.name.downcase
  digest_relation = Notifier.digest_object_relationship(digest_object, user)
  
  subdomain = digest == 'subdomain' ? digest_object : digest_object.subdomain
  key = "/#{digest}/#{digest_object.id}"

  # TODO: remove the digest_relation == 'none' after testing
  return if digest_relation == 'unsubscribed' || digest_relation == 'none'

  prefs = subscription_settings[digest][digest_relation]

  if !prefs
    #pp subscription_settings[digest]
    raise "No subscription settings for #{digest} #{digest_relation} for User #{user.id}"
  end

  ####
  # Respect the user's notification settings. Compare with time since we last
  # sent them a similar digest email.
  can_send = true
  last_digest_sent_at = emails_sent[key]
  if last_digest_sent_at
    sec_since_last = Time.now() - Time.parse(last_digest_sent_at)
    interval = email_me_no_more_than prefs['subscription']
    can_send = sec_since_last >= interval
  end

  return if !can_send
  #####

  ####
  # Check notifications to determine if a valid triggering event occurred
  do_send = false

  event_prefs = prefs['events']
  for event, ns in notifications

    for event_relation, nss in ns
      for notification in nss
        event_relation = notification.event_object_relationship 

        # if !event_prefs[event] || !event_prefs[event][event_relation]
        #   pp 'missing event prefs for', event, event_relation
        # end

        if event_prefs[event] && event_prefs[event][event_relation] && \
           event_prefs[event][event_relation]['email_trigger']

          do_send = !notification.read_at && \
                    Time.now() - notification.created_at > BUFFER
          break if do_send
        end
      end
    end
  end

  mail = nil

  if do_send

    channel = Notifier.subscription_channel(digest_object, user)
    mail = DigestMailer.send(digest, digest_object, user, notifications, channel)

    # record that we've sent these notifications
    # TODO: Enable this when appropriate
    for v in notifications.values
      for vv in v.values
        for n in vv      
          n.sent_email = true; n.save
        end
      end
    end

    emails_sent[key] = Time.now().to_s
    user.save
  end

  mail 

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
    multipler = 24 * 60 * 60
  when 'month'
    multipler = 30 * 24 * 60 * 60      
  else
    raise "#{unit} is not a supported unit for digests"
  end

   multipler / num.to_i
end

