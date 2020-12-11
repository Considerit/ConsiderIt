

task :migrate_tags => :environment do 



  pp 'Migrate checklists user tag datatype'
  Subdomain.all.each do |s|
    if s.customizations 
      customizations = s.customization_json()

      if customizations['auth_questions']
        for question in customizations['auth_questions']
          if question["input"] == "checklist"
            prefix = "#{question["tag"][0..question["tag"].length - '.editable'.length - 1]}:"
            for u in User.where(:registered=>true).where("tags like '%#{prefix}%'")

              tags = JSON.load(u.tags)
              matches = []
              tags.each do |k,v|
                if k.index(prefix)
                  matches.append k.split(':')[1][0..-(" .editable".length + 1)]
                  tags.delete(k)
                end
              end
              vals = matches.join(',')
              tags[question["tag"]] = vals 
              pp "User #{u.name} has tag #{prefix} with values #{vals}"
              pp tags

              u.tags = JSON.dump(tags)
              u.save
            end
          end
        end
      end
    end
  end


  editable = {}
  noneditable = {}

  User.where(:registered => true).where("tags is not NULL").each do |u|
    tags = JSON.load(u.tags)
    replace = {}

    tags.each do |k,v|
      if k.index '.editable'
        editable[k] = 1
        replace[k] = k.split('.editable')[0]
      else 
        noneditable[k] = 1
      end
    end
    replace.each do |old_tag, new_tag|
      tags[new_tag] = tags[old_tag]
      tags.delete(old_tag)
    end

    # u.tags = JSON.dump(tags)
    # u.save

  end

  # pp editable
  # pp '         \n\n\n'
  # pp noneditable


  refactor_opinion_filter = {}

  pp 'Create user_tags configuration and add depends_on to opinion_filters'
  # [Subdomain.find_by_name('denverclimateaction')].each do |s|

  Subdomain.all.each do |s|

    if s.customizations 
      changed = false

      customizations = s.customization_json()

      old_tag2new_tag = {}
      user_tags = {}

      if customizations['auth_questions']
        for question in customizations['auth_questions']
          tag = question['tag'].split('.editable')[0].strip
          user_tags[tag] = {
            'self_report' => question,
            'visibility' => 'host-only'   # 'open' visibility will be migrated later
          }
          old_tag2new_tag[question['tag']] = tag
          question.delete('tag') # now we don't need this anymore
        end

      end


      if customizations['opinion_filters']
        admin_only = customizations.has_key?("opinion_filters_admin_only") ? customizations["opinion_filters_admin_only"] : false
        
        if customizations.has_key?("opinion_filters_admin_only")
          customizations.delete("opinion_filters_admin_only")
        end

        tag2visibility = {}

        # pp s.name, customizations['opinion_filters']

        for filter in customizations['opinion_filters']
          visibility = (filter.has_key?("admin_only") ? filter["admin_only"] : admin_only) ? 'host-only' : 'open'

          # figure out which user tags this filter depends on
          tags_used = []
          old_tag2new_tag.each do |old_tag, new_tag|
            if filter['pass'].index("'#{old_tag}'") || filter['pass'].index("\"#{old_tag}\"")
              tags_used.append new_tag          
            end
          end

          # account for non-editable tags that aren't in old_tag2new_tag
          for tag in noneditable.keys
            if filter['pass'].index("'#{tag}'") || filter['pass'].index("\"#{tag}\"")
              tags_used.append tag          
            end
          end


          filter['depends_on'] = tags_used
          # pp "#{s.name}: #{filter['label']} depends on #{tags_used}"

          for tag in tags_used
            # taking the most liberal visibility
            if !tag2visibility.has_key?(tag) || visibility != 'host-only'
              tag2visibility[tag] = visibility
            end
          end

          if filter['pass'].index('.editable')
            if s.customizations.index('checklist') # this is only for one forum, so hardcoding it a bit
              matches = filter['pass'].match(/'([a-z\- ]+):' \+ '([a-zA-Z\- ]+)'/)
              tag = matches[1]
              option = matches[2]
              filter['pass'] = "#javascript\nfunction(u) {\n   passes_tag_filter(u, '#{tag}', '#{option}') }"
            end

            filter['pass'] = filter['pass'].gsub('.editable','')
          end


        end 

        # account for any non-editable tags that aren't configured in auth_questions. 
        # needs to come after opinion filters migration because the filters' dependencies 
        # determine if a non-editable tag is associated with the forum
        tag2visibility.each do |tag, visibility| 
          if !user_tags.has_key?(tag)
            user_tags[tag] = {
              'visibility' => visibility
            }
          end
        end

        # now we have to go back and update the visiblity given the filters
        if user_tags.keys.length > 0 
          user_tags.each do |tag, vals|
            if tag2visibility.has_key?(tag) && tag2visibility[tag] != 'host-only'
              vals['visibility'] = tag2visibility[tag]
              # pp "#{s.name}: Set visibility of #{tag} to #{tag2visibility[tag]}"
            end
          end
        end

        changed = true 
      end

      if user_tags.keys.length > 0
        # pp s.name, user_tags
        if customizations['auth_questions']
          customizations.delete('auth_questions')
        end
        customizations['user_tags'] = user_tags
        changed = true        
      end

      if changed
        # s.customizations = JSON.dump(customizations)
        # s.save  
      end
    end
  end

end