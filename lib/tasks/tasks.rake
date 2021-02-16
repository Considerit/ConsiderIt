task :update_when_point_dragged_out => :environment do 

  points = ActiveRecord::Base.connection.execute("select points.id from opinions, points,users where opinions.user_id=users.id and opinions.proposal_id=points.proposal_id and opinions.published=1 and users.id=points.user_id and users.registered=1 and points.subdomain_id in (3692,3624,3626,3661,3698) and json_length(includers) = 0")
  
  for pid in points
    pnt = Point.find(pid[0])
    o = Opinion.where(:proposal_id=>pnt.proposal_id, :user_id=>pnt.user_id)[0]
    o.include(pnt, pnt.subdomain)
    pp "Included #{pnt.id} for user #{pnt.user.name} in #{pnt.subdomain.name}"
  end

end

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


task :migrate_roles => :environment do 
  Subdomain.all.each do |sub|
    subroles = sub.user_roles
    next if subroles['moderator'].length == 0 && subroles['proposer'].length == 0 

    pp sub.name, subroles['moderator'], subroles['proposer']
  end
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




task :migrate_proposal_roles => :environment do 
  subs = {}
  Proposal.all.each do |p|
    next if !p.subdomain
    v = p.user_roles
    next if v['observer'].include?('*')

    if !subs.include?(p.subdomain_id)
      subs[p.subdomain_id] = {}
    end 

    ['observer', 'opiner', 'commenter', 'writer', 'editor'].each do |role|
      #next if role == 'editor' && v[role].length == 1
      v[role].each do |u|
        if !subs[p.subdomain_id].include?(u)
          subs[p.subdomain_id][u] = 0
        end 
        subs[p.subdomain_id][u] += 1
      end
    end
     
  end

  subs.each do |sub, v|
    next if v.keys.length == 0 || (v.has_key?('*') && v.keys.length == 1)
    s = Subdomain.find(sub)
    subroles = s.user_roles
    given_access = {}
    ['admin', 'moderator', 'proposer', 'visitor'].each do |role|
      subroles[role].each do |u|
        given_access[u] = true
      end      
    end

    pp ''
    pp '----------'
    pp "#{s.name} (#{subroles['visitor'].include?('*') ? 'PUBLIC' : 'PRIVATE'})"
    v.each do |user, cnt|
      next if user == '*'
      if given_access[user]
        pp "    MENTIONED: #{user} #{cnt}"
      else 
        pp "  * EXCLUDED: #{user} #{cnt}"
      end
    end
  end
end