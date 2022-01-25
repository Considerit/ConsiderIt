task :migrate_pledges => :environment do 
  Subdomain.all.each do |subdomain|
    next if !subdomain.customizations

    customizations = subdomain.customizations

    if customizations['auth_require_pledge']

      if customizations['pledge']
        pledge_q = customizations['pledge'].join(' ')
        customizations.delete('pledge')
      else 
        pledge_q = 'I pledge to be civil and to use only one account'
      end 

      customizations.delete('auth_require_pledge')

      user_tags = customizations.fetch('user_tags', [])

      pledge = {
        "key" => "#{subdomain.name}-pledge_taken", 
        "no_opinion_view" => true, 
        "visibility" => "host-only", 
        "self_report" => {
           "input" => "boolean", 
           "question" => pledge_q,
           "required" => true
        }
      }

      user_tags.push pledge 

      # pp "Adding Pledge to #{subdomain.name}", user_tags, pledge
      customizations['user_tags'] = user_tags

      subdomain.save 
    end 
  end

end


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




task :migrate_user_tags_to_list => :environment do 

  Subdomain.all.each do |subdomain|
    next if !subdomain.customizations

    customizations = subdomain.customizations

    if customizations['user_tags'] && !customizations['user_tags'].is_a?(Array)
      new_tags = []
      customizations['user_tags'].each do |tag,vals|
        vals["key"] = tag
        new_tags.push vals
      end
      customizations['user_tags'] = new_tags
      subdomain.save 
    end 
  end
end

task :migrate_opinion_views => :environment do 
  Subdomain.all.each do |subdomain|
    next if !subdomain.customizations
    customizations = subdomain.customizations
    if customizations['opinion_filters_default']
      pp 'DEFAULT FILTER', subdomain.name, customizations['opinion_filters_default']
    end
  end
end 

task :migrate_list_headers => :environment do 


  Subdomain.all.each do |subdomain|
    next if !subdomain.customizations
    
    customizations = subdomain.customizations

    customizations.each do |k,v|
      if k.match( /list\// )
        if v.has_key?('list_category') && v['list_category'].length > 0
          if v.has_key?('list_title') && v['list_title'].length > 0 && v['list_title'] != "How do you want Consider.it to help you?"
            pp "HAS TITLE ALREADY: #{v['list_title']}, eliminate #{v['list_category']}"
          else 
            pp "SET TITLE TO: #{v['list_category']}"
            v['list_title'] = v['list_category']
          end
          
        end
      end 
    end
    subdomain.save


  end
end