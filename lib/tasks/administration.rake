task :create_forum, [:forum_name] => :environment do |t, args|
  forum_name = args[:forum_name]
  host_email = APP_CONFIG[:super_admin_email]

  existing = Subdomain.find_by_name(forum_name)
  if existing
    pp "That forum already exists. Please choose a different name."
    return
  end 
  
  forum = Subdomain.new name: forum_name

  current_user = User.find_by_email host_email
  if !host_email
    pp "Can't create, no super admin"
    return
  end

  roles = forum.user_roles
  roles['admin'].push "/user/#{current_user.id}"
  roles['visitor'].push "*"
  forum.roles = roles

  forum.save
  
  require 'socket'
  ip = Socket.ip_address_list.map{|intf| intf.ip_address}
  pp "You may need to set a DNS A record for #{forum_name} for your domain that points to this server's ip (one of #{ip}) (e.g. at https://cloud.linode.com/domains)"
end

task :unsubscribe, [:email, :subdomain] => :environment do |t, args|
  email = args[:email]
  subdomain = args[:subdomain]
  User.unsubscribe(email, subdomain)
end

task :create_super_admin, [:email, :name, :password] => :environment do |t, args|
  user = User.find_by_email args[:email]
  if user 
    user.super_admin = true 
    user.save
  else 
    user = User.new
    user.name = args[:name]
    user.email = args[:email]
    user.password = args[:password]
    user.super_admin = true 
    user.complete_profile = false 
    user.verified = true 
    user.registered = true
    user.save 
  end 
end

task :freeze_inactive_forums => :environment do 

  Subdomain.all.each do |subdomain|
    last_proposal = subdomain.proposals.last
    next if !last_proposal || subdomain.name == 'galacticfederation' || subdomain.name == 'taskratchet'
    last_date = last_proposal.created_at 

    customizations = subdomain.customizations || {}

    if last_date < 1.year.ago && (!customizations.has_key?('contribution_phase') || customizations['contribution_phase'] != 'frozen')
      customizations['contribution_phase'] = 'frozen'
      subdomain.customizations = customizations
      subdomain.save 
      pp "Freezing #{subdomain.name}, last proposal #{last_date}"
    end 
  end
end
