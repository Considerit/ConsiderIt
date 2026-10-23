
task :compute_metrics => :environment do 
  begin
    Point.update_scores()
    Rails.logger.info "Updated point scores"
  rescue
    Rails.logger.info "Could not update point scores"
  end 
end

# For a weird bug we can't figure out that leaves an 
# inclusion without an associated point. 
# Remove this after we have a decent caching method for inclusions
task :clear_null_inclusions => :environment do
  Inclusion.where(:point_id => nil).destroy_all
end

task :fix_active_in => :environment do 
  User.fix_active_in
end

task :clear_old_users => :environment do 
  ActiveRecord::Base.connection.execute("DELETE FROM users WHERE registered=false AND complete_profile=0 AND created_at < DATE_SUB(NOW(), INTERVAL 2 MONTH)")
end

task :clear_old_sessions => :environment do 
  ActiveRecord::Base.connection.execute("DELETE FROM sessions WHERE updated_at < now() - interval 1 YEAR")
end


task :subscription_changes_from_default => :environment do 

  results = {'send_emails': {}, 'subscriptions': 0}

  User.where(:registered => true).each do |u|
    u.active_in.each do |sub|
      begin
        s = Subdomain.find(sub)
      rescue
        next
      end
      settings = u.subscription_settings(s)

      defaults = Notifier::config(s)

      for event, config in defaults
        if settings.has_key?(event) && config['email_trigger_default'] != settings[event]['email_trigger']
          # pp "#{u.name} changed #{event} from #{config['email_trigger_default']} to #{settings[event]['email_trigger']} for #{s.name}"
          if !results.has_key?(event)
            results[event] = {}
          end
          cnt = results[event].fetch(settings[event]['email_trigger'], 0)
          results[event][settings[event]['email_trigger']] = cnt + 1
        end
      end

      if settings['send_emails'] != settings['default_subscription']
        cnt = results[:send_emails].fetch(settings['send_emails'], 0) 
        results[:send_emails][settings['send_emails']] = cnt + 1
      end 

      results[:subscriptions] += 1
    end
  end
  pp results
end


task :fix_duplicate_opinions => :environment do
  total_dups = 0  
  Proposal.where(published: true).each do |p|
    dups = ActiveRecord::Base.connection.execute("SELECT user_id, COUNT(user_id) AS cnt FROM opinions WHERE proposal_id = #{p.id} GROUP BY user_id having cnt > 1")
    if dups.count > 0 

      dups.each do |result|
        user_id = result[0]

        pp 'dups found', p.name, p.subdomain.name, User.find(user_id).name

        opinions = p.opinions.where(:user_id => user_id).order(:updated_at)
        total_dups += opinions.count - 1

        to_delete = []
        opinions.each_with_index do |o, idx|
          if idx != opinions.count - 1
            pp "DELETING #{idx + 1} / #{opinions.count}"
            to_delete.push o
          end
        end

        to_delete.each do |o|
          o.delete
        end

      end
    end

  end

end

