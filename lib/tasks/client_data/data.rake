require 'csv'
require 'pp'

task :export, [:sub] => :environment do |t, args|
  sub = args[:sub] || 'mo825'

  subdomain = Subdomain.find_by_name(sub)

  CSV.open("lib/tasks/client_data/export/#{subdomain.name}-opinions.csv", "w") do |csv|
    csv << ["proposal", 'created', "username", "email", "opinion", "#points"]
  end

  CSV.open("lib/tasks/client_data/export/#{subdomain.name}-points.csv", "w") do |csv|
    csv << ['id', 'proposal', 'type', 'created', "author", "valence", "summary", "details", 'author_opinion', '#inclusions', '#comments']
  end

  CSV.open("lib/tasks/client_data/export/#{subdomain.name}-inclusions.csv", "w") do |csv|
    csv << ['proposal', 'point', 'user id', 'user email']
  end


  CSV.open("lib/tasks/client_data/export/#{subdomain.name}-stance-changes.csv", "w") do |csv|
    csv << ['proposal', 'user', 'user email', 'stance']

    subdomain.logs.where("what='move slider'").where('who is not NULL').each do |log| 
      csv << [log.where.split('/')[1], log.who, User.find(log.who).email, log.details.split(':')[1].split('}')[0]]
    end
  end


  fields = "zip", "gender", "age", "ethnicity", "education", "race", "home", "hispanic", "hala_focus_group"
  fields = []
  CSV.open("lib/tasks/client_data/export/#{subdomain.name}-users.csv", "w") do |csv|
    row = ['email', 'name', 'date joined'] 
    for field in fields 
      row.append field 
    end 
    csv << row
  end

  subdomain.proposals.each do |proposal|

    CSV.open("lib/tasks/client_data/export/#{subdomain.name}-opinions.csv", "a") do |csv|
      proposal.opinions.published.each do |opinion|
        user = opinion.user
        csv << [proposal.slug, opinion.created_at, user.name, user.email.gsub('.ghost', ''), opinion.stance, user.points.where(:proposal_id => proposal.id).count]
      end
    end

    CSV.open("lib/tasks/client_data/export/#{subdomain.name}-points.csv", "a") do |csv|

      proposal.points.published.each do |pnt|
        opinion = pnt.user.opinions.find_by_proposal_id(pnt.proposal.id)
        csv << [pnt.id, pnt.proposal.slug, 'POINT', pnt.created_at, pnt.hide_name ? 'ANONYMOUS' : pnt.user.email.gsub('.ghost', ''), pnt.is_pro ? 'Pro' : 'Con', pnt.nutshell, pnt.text, opinion ? opinion.stance : '-', pnt.inclusions.count, pnt.comments.count]

        pnt.comments.each do |comment|
          opinion = comment.user.opinions.find_by_proposal_id(pnt.proposal.id)
          csv << [comment.id, pnt.proposal.slug, 'COMMENT', comment.created_at, comment.user.email.gsub('.ghost', ''), "", comment.body, '', opinion ? opinion.stance : '-', '', '']
        end
      end
    end

    CSV.open("lib/tasks/client_data/export/#{subdomain.name}-inclusions.csv", "a") do |csv|

      proposal.inclusions.each do |inc|
        next if !inc.point.published
        point = inc.point 
        user = inc.user
        csv << [point.proposal.slug, point.id, user.id, user.email] 
      end
    end


  end

  subdomain.users.each do |user|
    CSV.open("lib/tasks/client_data/export/#{subdomain.name}-users.csv", "a") do |csv|
      tags = {}
      for k,v in JSON.parse(user.tags) or {}
        if k == 'age.editable' && ['hala','engageseattle'].include?(subdomain.name)
          if v.to_i > 0          
            v = v.to_i

            if v < 20
              v = '0-20'
            elsif v > 70
              v = '70+'
            else 
              v = "#{10 * ((v / 10).floor)}-#{10 * ((v / 10).floor + 1)}"
            end 
          else 
            next 
          end
        end 
        tags[k.split('.')[0]] = v
      end

      row = [user.email, user.name, user.created_at]
      for field in fields 
        row.append tags.has_key?(field) ? tags[field] : ""
      end
      csv << row
    end
  end

end



# has special questionaire format
task :export_cprs, [:sub] => :environment do |t, args|
  sub = args[:sub] || 'engage-cprs'

  subdomain = Subdomain.find_by_name(sub)

  CSV.open("lib/tasks/client_data/export/#{subdomain.name}-tools.csv", "w") do |csv|
    csv << ["category", "tool", "overall first priority", "overall top 5 priority"]
  end

  CSV.open("lib/tasks/client_data/export/#{subdomain.name}-explanations.csv", "w") do |csv|
    csv << ["category", "tool", "name", "email", "top priority explanation"]
  end

  subdomain.proposals.where('id < 7382').each do |proposal|
    first_priority = proposal.opinions.published.where(:stance => 1.0).count 
    top5_priority = first_priority + proposal.opinions.published.where(:stance => 0.25).count 

    CSV.open("lib/tasks/client_data/export/#{subdomain.name}-tools.csv", "a") do |csv|
      csv << [proposal.cluster, proposal.name, first_priority, top5_priority]
    end

    CSV.open("lib/tasks/client_data/export/#{subdomain.name}-explanations.csv", "a") do |csv|
      explanations = []
      proposal.opinions.published.where(:stance => 1.0).where('explanation is not null').each do |opinion|
        user = opinion.user
        csv << [proposal.cluster, proposal.name, user.name, user.email.gsub('.ghost',''), opinion.explanation]
      end
    end

  end

end

