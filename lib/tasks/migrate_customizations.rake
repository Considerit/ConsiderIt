task :migrate_lists_and_tabs => :environment do 
  Subdomain.all.each do |subdomain|
    next if !subdomain.customizations

    customizations = subdomain.customizations

    if customizations['homepage_tabs']
      tabs = customizations['homepage_tabs']
      tabs.each do |tab|

      end 
    end

    if customizations['homepage_list_order'] && customizations['homepage_tabs']
      customizations.delete 'homepage_list_order' # already manually migrated
    elsif customizations['homepage_list_order']
      customizations['lists'] = customizations['homepage_list_order']
      customizations.delete 'homepage_list_order'
      # pp "Migrated list order for #{subdomain.name}", customizations['default_page']
    end

    if customizations['ordered_lists']
      customizations['lists'] = customizations['ordered_lists']
      customizations.delete 'ordered_lists'
    end



    if customizations['homepage_tab_views']
      views = customizations['homepage_tab_views']
      tabs = customizations['homepage_tabs']
      tabs.each do |tab|
        if views.has_key?(tab['name'])
          tab['render_page'] = views[tab['name']]
        end
      end 

      # pp "Migrated tab_views for #{subdomain.name}", tabs
      customizations.delete 'homepage_tab_views'
    end

    if customizations['homepage_default_sort_order']
      customizations['default_proposal_sort_order'] = customizations['homepage_default_sort_order']
      customizations.delete 'homepage_default_sort_order'

      # pp "Migrated default_sort order for #{subdomain.name}", customizations['default_page']
    end


    subdomain.save


  end
end


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


task :migrate_to_bus_fetch => :environment do 
  Subdomain.all.each do |subdomain|
    next if !subdomain.customizations

    customizations = subdomain.customizations

    def process_object(parent, k, v)
      if v.respond_to?(:key)
        v.each do |kk,vv|
          process_object(v, kk, vv)
        end

      elsif v.is_a?(Array)

        v.each do |vv|
          process_object(v, nil, vv)
        end

      elsif v.is_a?(String) && v.include?(" fetch")
        if !k
          pp("fetch found in array!", v, parent)
        else
          pp("updating from", v)
          parent[k].gsub!(" fetch", " bus_fetch")
          pp("\t\tto", parent[k])

        end
      end
    end

    customizations.each do |k,v|
      process_object(customizations,k,v)
    end
    

    subdomain.save
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


task :migrate_list_names => :environment do 


  Subdomain.all.each do |subdomain|
    next if !subdomain.customizations
    
    customizations = subdomain.customizations

    changed = false
    changes = {}
    customizations.each do |k,v|
      if k.match( /list\// )
        clust = k[5..-1]

        if clust.index('/') || clust.index('.') || clust.index('#') || clust.index('&') || clust.index('?') || clust.index(':')
          new_name = "#{slugify(clust)}-#{(rand() * 100).round}"
          new_key = "list/#{new_name}"
          changed = true
          changes[k] = new_key
        end
      end 
    end

    changes.each do |old, updated|
      # pp "SET KEY #{old} TO: #{updated}"
      v = customizations[updated] = customizations[old]
      customizations.delete(old)
      if v.has_key?('key')
        v['key'] = updated
      end 

      old_clust = old[5..-1]
      new_clust = updated[5..-1]

      props_to_update = subdomain.proposals.where(cluster: old_clust)
      if props_to_update.count == 0 
        pp "NO PROPOSALS FOUND FOR #{old_clust} #{old}"
      end
      props_to_update.each do |p|
        p.cluster = new_clust
        p.save
      end

      subdomain.customizations = JSON.parse(JSON.dump(subdomain.customizations).gsub("\"#{old}\"", "\"#{updated}\""))

    end 
    subdomain.save if changed
  end
end


