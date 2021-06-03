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