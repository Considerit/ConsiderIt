task :migrate_to_payments => :environment do 

  Subdomain.all.each do |subdomain|

    created_by = subdomain.user_roles["admin"][0]
    if created_by
      user = created_by.split('/')[-1]  
      begin
        user = user.to_i
        subdomain.created_by = user
        subdomain.save
        # pp "SET USER TO #{subdomain.name} #{user} #{subdomain.created_by}"
      rescue 
        pp "COULD NOT FIND USER #{user.to_i}"
      end
    end

    if subdomain.plan > 0
      pp "PAID #{subdomain.created_by}"
      if subdomain.created_by
        u = User.find subdomain.created_by

        u.paid_forums += 1
        pp "saving user #{u.name}", u.subscriptions
        u.save
        pp u.name, u.email, u.paid_forums
      else 
        pp "HUH?", subdomain.name, subdomain.user_roles
      end
    end
  end
end

task :migrate_for_onboarding => :environment do 
  Subdomain.all.each do |subdomain|
    customizations = subdomain.customizations || {}

    customizations['onboarding_complete'] = true
    subdomain.customizations = customizations
    subdomain.save

  end
end