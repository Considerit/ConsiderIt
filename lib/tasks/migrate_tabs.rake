task :migrate_tags => :environment do 

  show_all_position = {
    "dao" => 0,
    "kanaeokana" => 0,
    "bradywalkinshaw" => 0,
    "BITNATION" => 0,
    "newblueplan" => 1,
    "internethealthreport" => 1,
    "internetparty" => 0,
    "yangdao" => 0,
    "ainaalohafutures" => 0,
    "mozilla-trustworthy-ai" => 1,
    "sanleandroclimateaction" => 0,
    "sanleandroaccionclimatica" => 0,
    "ummnhdemo3" => 0,
    "climateactioncolumbus" => 0,
    "fremontclimateaction" => 0,
  }
  Subdomain.all.each do |subdomain|
    next if !subdomain.customizations

    customizations = subdomain.customizations
    tabs = customizations["homepage_tabs"]
    upgraded_format = false
    if tabs && tabs.is_a?(Hash)
      updated = []
      for k,v in tabs
        tab = {
          "name" => k,
          "lists" => v
        }
        updated.push tab
      end
      customizations["homepage_tabs"] = updated 
      subdomain.save
      upgraded_format = true 
      pp "Upgraded tab format for #{subdomain.name}"
    end
    if upgraded_format
      customizations = subdomain.customizations
      tabs = customizations["homepage_tabs"]
      if tabs
        has_show_all = nil 
        tabs.each_with_index do |tab, idx|
          if tab["name"] == 'Show all'
            has_show_all = idx 
          end
        end

        if has_show_all != nil && has_show_all != show_all_position[subdomain.name]
          pp "Moved show all for #{subdomain.name} to #{show_all_position[subdomain.name]}"
          tabs.insert(show_all_position[subdomain.name], tabs.delete_at(has_show_all))
          subdomain.save
        end

        if has_show_all == nil && !customizations['homepage_tabs_no_show_all']
          show_all_tab = {
            "name": "Show all",
            "lists": ['*']
          }
          tabs = customizations["homepage_tabs"]
          tabs.insert show_all_position[subdomain.name], show_all_tab
          pp "#{subdomain.name} has implicit show all tab; replaced with explicit"
          subdomain.save
        end

      end
              
    end
    customizations = subdomain.customizations
    if customizations['homepage_tabs_no_show_all']
      pp "removed #{subdomain.name} homepage_tabs_no_show_all=#{customizations['homepage_tabs_no_show_all']}"
      customizations.delete('homepage_tabs_no_show_all')
      subdomain.save
    end
  end
end