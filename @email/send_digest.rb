# wait at least 2 min before sending any notification
BUFFER = 2 * 60 

def send_digest(user, digest_object, notifications, subscription_settings, deliver = true)
  digest = digest_object.class.name.downcase
  
  subdomain = digest == 'subdomain' ? digest_object : digest_object.subdomain
  key = "/#{digest}/#{digest_object.id}"

  send_emails = subscription_settings['send_emails']
  return if !send_emails

  ####
  # Respect the user's notification settings. Compare with time since we last
  # sent them a similar digest email.
  can_send = true

  last_digest_sent_at = user.emails_received[key]
  if last_digest_sent_at
    sec_since_last = Time.now() - Time.parse(last_digest_sent_at)
    interval = email_me_no_more_than send_emails
    can_send = sec_since_last >= interval
  end

  return if !can_send
  #####

  ####
  # Check notifications to determine if a valid triggering event occurred
  do_send = false

  for event, ns in notifications

    for event_relation, nss in ns

      for notification in nss
        event_relation = notification.event_object_relationship 

        if subscription_settings.key? "#{event}:#{event_relation}"
          key = "#{event}:#{event_relation}"
        else 
          key = event
        end

        if !subscription_settings[key]
          raise 'missing event prefs for', event, event_relation
        end

        if subscription_settings[key] && subscription_settings[key]['email_trigger']

          do_send = !notification.read_at && \
                    Time.now() - notification.created_at > BUFFER
          break if do_send
        end
      end
    end
  end

  mail = nil

  if do_send

    mail = DigestMailer.send(digest, digest_object, user, notifications)
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
  when 'week'
    multiplier = 7 * 24 * 60 * 60
  when 'month'
    multiplier = 30 * 24 * 60 * 60      
  else
    raise "#{unit} (#{interval}) is not a supported unit for digests"
  end

   multiplier / num.to_i
end

