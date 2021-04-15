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

task :migrate_moderation => :environment do 
  Subdomain.all.each do |s|
    moderatable_models = ['points', 'comments', 'proposals']

    policy = 0
    moderatable_models.each do |model|
      ppolicy = s["moderate_#{model}_mode"]
      if !policy && ppolicy > 0
        policy = ppolicy 
      elsif policy < ppolicy 
        policy = ppolicy
      end
    end

    if policy > 0 
      pp "Setting #{s.name} to #{policy} from #{s["moderate_proposals_mode"]} #{s["moderate_points_mode"]} #{s["moderate_comments_mode"]}"
    end 
    s.moderation_policy = policy 
    s.save

  end
end

task :migrate_roles => :environment do 

  Subdomain.all.each do |s|
    roles = s.roles || {}

    if roles['moderator']
      s.roles.delete('moderator')
      s.save
      pp "removed moderator role from #{s.name}"
    end 
  end

  Proposal.all.each do |p|
    subroles = p.roles ? p.roles.deep_dup : {}

    next if subroles['participant']

    begin
      has_wildcard = subroles['writer'].include?('*') || subroles['opiner'].include?('*') || subroles['commenter'].include?('*')
    rescue
      has_wildcard = true
    end

    modified = false

    if !has_wildcard
      subroles['participant'] = []
      modified = true
    end

    if subroles["observer"] == ["*", "*"]
      subroles["observer"] = ["*"]
      modified = true 
    end

    if subroles['writer'] || subroles['opiner'] || subroles['commenter']
      subroles.delete('writer')
      subroles.delete('opiner')
      subroles.delete('commenter')
      modified = true 
    end

    if modified
      p.roles = subroles
      p.save
      pp "migrated roles of #{p.subdomain.name} #{p.id}"
      pp p.roles

      p.reload
      pp p.roles
    end
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




