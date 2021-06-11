task :migrate_frozen => :environment do 

  Subdomain.all.each do |subdomain|
    next if !subdomain.customizations

    customizations = subdomain.customizations

    if customizations['frozen']        
      customizations['contribution_phase'] = 'frozen'
      customizations.delete('frozen')
      subdomain.save 
    end 
  end
end

task :migrate_opinion_filters => :environment do 

  Subdomain.all.each do |subdomain|
    next if !subdomain.customizations

    customizations = subdomain.customizations

    if customizations['opinion_filters']
      customizations['opinion_views'] = customizations['opinion_filters']
      customizations.delete('opinion_filters')
      subdomain.save 
    end 
  end
end