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
    else 
      pp "Not setting #{s.name} title to #{s.app_title} because already has #{banner['title']}" 
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

end