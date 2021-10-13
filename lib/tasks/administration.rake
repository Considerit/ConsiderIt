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
  pp "You may need to set a DNS A record for your domain that points to this server's ip (one of #{ip}) (e.g. at https://linode.com)"
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
    user.save 
  end 
end
