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

  pp 'Migrate lists'
  Subdomain.all.each do |s|
    if s.customizations 
      changed = false

      if s.customizations.index('list_show_new_button')
        s.customizations = s.customizations.gsub('list_show_new_button', 'list_permit_new_items') 
        changed = true 
        pp "converted list_show_new_button => list_permit_new_items for #{s.name}"
      end 

      customizations = JSON.load(s.customizations || "{}")

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
          cust['list_title'] = k
          changed = true
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

end