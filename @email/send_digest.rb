# wait at least 2 min before sending any notification
BUFFER = 2 * 60 

def send_digest(subdomain, user, notifications, subscription_settings, deliver = true)
  
  send_emails = subscription_settings['send_emails']
  return if !send_emails

  ####
  # Respect the user's notification settings. Compare with time since we last
  # sent them a similar digest email.
  can_send = true
  send_key = "/subdomain/#{subdomain.id}"

  last_digest_sent_at = user.emails_received[send_key]
  if last_digest_sent_at
    sec_since_last = Time.now() - Time.parse(last_digest_sent_at)
    interval = email_me_no_more_than send_emails
    can_send = sec_since_last >= interval
  end

  if user.id == 1701 && !can_send
    pp "CANT SEND BECAUSE #{last_digest_sent_at} < #{email_me_no_more_than send_emails}"
  end

  return if !can_send
  #####

  ####
  # Check notifications to determine if a valid triggering event occurred
  do_send = false

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
            break if do_send
          end

        end
      end
    end
  end

  if user.id == 1701 && !do_send
    pp "NAH, wont send because no triggering events"
  end


  mail = nil

  if do_send

    mail = DigestMailer.digest(subdomain, user, notifications)
    if deliver
      mail.deliver_now

      # record that we've sent these notifications
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

      user.sent_email_about(send_key)

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

