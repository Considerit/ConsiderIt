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