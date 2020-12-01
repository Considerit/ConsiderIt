task :migrate_customizations => :environment do 

  pp 'migrate branding'
  Subdomain.where("branding is not NULL").each do |s|
    branding = JSON.load(s.branding)
    customizations = JSON.load(s.customizations || "{}")

    customizations['banner'] ||= {}
    banner = customizations['banner']

    changed = false 

    branding.each do |k,v|

      if k == 'primary_color' && v != '#eee' && v != ""
        banner['background_css'] = v
        changed = true
      elsif k == 'masthead_header_text' && v != ""
        banner['title'] = v
        changed = true
      end
    end

    if changed 
      s.customizations = JSON.dump(customizations)
      pp "Imported branding #{s.name}: ", banner #JSON.dump(customizations)
      s.save 
    end

  end

  pp '\n************\n'
  pp 'migrating subdomain.app_title'
  Subdomain.where("app_title is not NULL AND app_title != name AND app_title != ''").each do |s|
    customizations = JSON.load(s.customizations || "{}")

    customizations['banner'] ||= {}
    banner = customizations['banner']

    if !banner.has_key?('title')
      banner['title'] = s.app_title
      s.customizations = JSON.dump(customizations)
      pp "Imported title for #{s.name}: #{banner['title']}"
      s.save 
      # else 
      #   pp "Not setting #{s.name} title to #{s.app_title} because already has #{banner['title']}" 
    end 
  end




  pp '\n************\n'

  pp 'Migrate customizations'
  Subdomain.all.each do |s|
    changed = false
    if s.customizations 
      customizations = JSON.load(s.customizations || "{}")

      if customizations.has_key?('background')
        customizations['banner'] ||= {}
        customizations['banner']['background_css'] = customizations['background']
        customizations.delete('background')

        changed = true
      end

      if customizations.has_key?('prompt')
        customizations['banner'] ||= {}
        customizations['banner']['title'] = customizations['prompt']
        customizations.delete('prompt')
        changed = true
      end

      if changed 
        pp "Migrated customizations for #{s.name}: ", customizations['banner'] #JSON.dump(customizations)
        s.customizations = JSON.dump(customizations)
        s.save 
      end

    end
  end


  pp '\n************\n'

  pp 'Migrate lists & references to lists'
  Subdomain.all.each do |s|
    if s.customizations 
      changed = false

      if s.customizations.index('list_show_new_button')
        s.customizations = s.customizations.gsub('list_show_new_button', 'list_permit_new_items') 
        changed = true 
        pp "converted list_show_new_button => list_permit_new_items for #{s.name}"
      end 

      customizations = JSON.load(s.customizations || "{}")

      if customizations.has_key?('homepage_lists_to_always_show')
        customizations.delete('homepage_lists_to_always_show')
        changed = true
      end

      customizations.each do |key, val|
        if key.match 'list/'

          if val.has_key?("list_one_line_desc")
            val['list_description'] = val['list_one_line_desc']
            val.delete('list_one_line_desc')
            pp 'moved to list_description', key
            changed = true
          end

          if val.has_key?('list_label')
            val['list_title'] = val['list_label']
            val.delete('list_label')
            pp 'moved to list_title', key
            changed = true 
          end 

          if val.has_key?('list_label_style')
            val['list_title_style'] = val['list_label_style']
            val.delete('list_label_style')
            pp 'moved to list_title_style', key
            changed = true 
          end 

          if val.has_key?('list_items_title')
            val['list_category'] = val['list_items_title']
            val.delete('list_items_title')
            changed = true
          end
        elsif key == 'homepage_tabs'
          new_tabs = {}
          migrated_tabs = false
          val.each do |tab, lists|
            if lists.length > 0 && !lists[0].start_with?("list/")
              new_tabs[tab] = lists.map.each do |list_name|
                if list_name == 'list/*' || list_name == '*'
                  '*'
                else 
                  "list/#{list_name}"
                end 
              end
              changed = migrated_tabs = true
            end
          end
          if migrated_tabs
            customizations[key] = new_tabs
          end
        elsif key == 'homepage_list_order'
          if val.length > 0 && !val[0].start_with?("list/")
            customizations[key] = val.map {|list_name| "list/#{list_name}"}
            changed = true 
          end
        end  

      end
      
      if changed 
        s.customizations = JSON.dump(customizations)
        s.save  
      end

    end
  end


  pp 'Migrate list permissions'
  Subdomain.all.each do |s|
    if s.customizations 
      changed = false

      customizations = s.customization_json()
      if !s.user_roles['proposer'].index('*') && !customizations.has_key?('list_permit_new_items')
        customizations['list_permit_new_items'] = false
        pp "CHANGED default show new button", s.name
        changed = true
      end
      
      if changed 
        s.customizations = JSON.dump(customizations)
        s.save  
      end

    end
  end


  pp '\n************\n'

  pp 'Assign proposal cluster value where appropriate'
  Subdomain.all.each do |s|
    lists = {}

    changed = false

    s.proposals.all.each do |p|
      if p.cluster && p.cluster != "Test question"
        lists[p.cluster] = 1
      end 
    end 

    customizations = JSON.load(s.customizations || "{}")
    customizations.each do |key, val|
      if key.match 'list/'
        lists[key[5..-1].strip] = 1
      end
    end

    lists.each do |k,v|
      list_key = "list/#{k}"
      if customizations.has_key?(list_key) 
        cust = customizations[list_key]
        if cust.has_key?('list_title') && cust['list_title'].strip.length > 0
          
          if k != cust['list_title'] && !k.match('-')

            if !cust.has_key?('list_description')
              cust['list_category'] = cust['list_title']
              cust.delete('list_title')
              changed = true
            else 
              cust['list_category'] = cust['list_opinions_title']  = ""             
              changed = true
            end
          end

        elsif cust.has_key?('list_description')
          if cust.has_key?('list_title') && cust['list_title'].length > 0
            # no op; 
            a = 1
          else 
            cust['list_title'] = k
            changed = true
          end

        else 
          cust['list_category'] = k
          changed = true
        end
      end
    end 

    if changed 
      s.customizations = JSON.dump(customizations)
      s.save  
    end

  end


  pp '\n************\n'

  pp 'Finalizing list configs'
  Subdomain.all.each do |s|
    lists = {}

    changed = false

    s.proposals.all.each do |p|
      if p.cluster && p.cluster != "Test question"
        lists[p.cluster] = 1
      end 
    end 

    customizations = JSON.load(s.customizations || "{}")
    customizations.each do |key, val|
      if key.match 'list/'
        if val.has_key?('list_title') && !val.has_key?('list_description') && (!val.has_key?('list_category') && !val.has_key?('list_opinions_title'))
          val['list_category'] = val['list_opinions_title']  = ""
          changed = true
        end
      end
    end

    if changed 
      s.customizations = JSON.dump(customizations)
      s.save  
    end

  end




  pp 'Migrate informational lists'
  Subdomain.all.each do |s|
    if s.customizations 
      changed = false

      customizations = JSON.load(s.customizations || "{}")

      customizations.each do |key, val|
        if key.match 'list/'
          matcher = if val.has_key?("list_permit_new_items")
                      val 
                    else 
                      val
                    end

          if (matcher.has_key?("list_permit_new_items") && !matcher["list_permit_new_items"]) && val.has_key?('list_description')
            proposals = s.proposals.where(:cluster => key[5..-1])
            has_proposals = proposals.count > 0 
            if !has_proposals
              val['list_category'] = ""
              val['list_opinions_title'] = ""
              changed = true 
            end
          end
        end
      end
      if changed
        s.customizations = JSON.dump(customizations)
        s.save  
      end
    end
  end


end