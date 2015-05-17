# wait at least 2 min before sending any notification
BUFFER = 2 * 60 

def send_digest(user, digest_object, notifications, subscription_settings, deliver = true)
  digest = digest_object.class.name.downcase
  digest_relation = Notifier.digest_object_relationship(digest_object, user)
  
  subdomain = digest == 'subdomain' ? digest_object : digest_object.subdomain
  key = "/#{digest}/#{digest_object.id}"

  # TODO: remove the digest_relation == 'none' after testing
  return if digest_relation == 'unsubscribed' || digest_relation == 'none' 

  prefs = subscription_settings[digest][digest_relation]

  return if prefs['subscription'] == 'on-site'

  if !prefs
    #pp subscription_settings[digest]
    raise "No subscriptions for #{digest}-#{digest_object.id} relation -#{digest_relation}-#{digest_relation == nil} User-#{user.id} Subdomain-#{subdomain.name}"
  end


  ####
  # Respect the user's notification settings. Compare with time since we last
  # sent them a similar digest email.
  can_send = true

  last_digest_sent_at = user.emails_received[key]
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
    if deliver
      mail.deliver_now

      # record that we've sent these notifications
      for v in notifications.values
        for vv in v.values
          for n in vv      
            n.sent_email = true
            n.save
          end
        end
      end

      user.sent_email_about(key)

    end

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
    multiplier = 24 * 60 * 60
  when 'month'
    multiplier = 30 * 24 * 60 * 60      
  else
    raise "#{unit} (#{interval}) is not a supported unit for digests"
  end

   multiplier / num.to_i
end

