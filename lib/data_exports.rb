def stats(vals)
  total_score = 0 
  vals.each do |v|
    total_score += v
  end

  begin 
    avg_score = total_score / vals.length
  rescue
    avg_score = 0 
  end 

  differences = 0
  vals.each do |v|
    differences += (v - avg_score)**2
  end

  {
    total: total_score,
    avg: avg_score,
    std_dev: vals.length > 0 ? (differences/vals.length)**0.5 : 0
  }

end

module Exports

  def opinions(subdomain)
    fname = "#{subdomain.name}-opinions"
    heading = ["proposal_slug","proposal_name", 'created', "username", "email", "opinion", "#points"]
    rows = []
    rows.append heading 

    subdomain.proposals.each do |proposal|

      proposal.opinions.published.each do |opinion|
        user = opinion.user
        begin 
          rows.append [proposal.slug, proposal.name, opinion.created_at, user.name, user.email.gsub('.ghost', ''), opinion.stance, user.points.where(:proposal_id => proposal.id).count]
        rescue 
        end 
      end

    end

    rows
  end

  def points(subdomain)
    fname = "#{subdomain.name}-points"
    heading = ['proposal', 'type', 'created', "username", "author", "valence", "summary", "details", 'author_opinion', '#inclusions', '#comments']
    rows = []
    rows.append heading 

    subdomain.proposals.each do |proposal|
      proposal.points.published.each do |pnt|
        begin 
          opinion = pnt.user.opinions.find_by_proposal_id(pnt.proposal.id)
          rows.append [pnt.proposal.slug, 'POINT', pnt.created_at, pnt.hide_name ? 'ANONYMOUS' : pnt.user.name, pnt.hide_name ? 'ANONYMOUS' : pnt.user.email.gsub('.ghost', ''), pnt.is_pro ? 'Pro' : 'Con', pnt.nutshell, pnt.text, opinion ? opinion.stance : '-', pnt.inclusions.count, pnt.comments.count]

          pnt.comments.each do |comment|
            opinion = comment.user.opinions.find_by_proposal_id(pnt.proposal.id)
            rows.append [pnt.proposal.slug, 'COMMENT', comment.created_at, comment.user.name, comment.user.email.gsub('.ghost', ''), "", comment.body, '', opinion ? opinion.stance : '-', '', '']
          end
        rescue 
        end 
      end
    end

    rows
  end

  def proposals(subdomain)
    fname = "#{subdomain.name}-proposals"
    heading = ['slug', 'url', 'created', "username", "author", 'name', 'category', 'description', '#points', '#opinions', 'total_score', 'avg_score', 'std_deviation']
    rows = []
    rows.append heading 

    subdomain.proposals.each do |proposal|
      opinions = proposal.opinions.published

      s = stats opinions.map{|o| o.stance}

      rows.append [proposal.slug, "https://#{subdomain.host_with_port}/#{proposal.slug}", proposal.created_at, proposal.user.name, proposal.user.email.gsub('.ghost', ''), proposal.name, (proposal.category || 'Proposals'), proposal.description, proposal.points.published.count, opinions.count, s[:total], s[:avg], s[:std_dev]]
    end

    rows
  end

  def users(subdomain)
    fname = "#{subdomain.name}-users"
    fields = {}
    subdomain.users.each do |user|
      if !user.super_admin
        for k,v in JSON.parse( user.tags || '{}' )
          fields[k.split('.')[0]] = 1
        end
      end
    end 

    heading = ['email', 'name', 'date joined'] 
    fields = fields.keys()
    for field in fields 
      heading.append field 
    end 

    rows = []
    rows.append heading 

    subdomain.users.each do |user|
      
      tags = {}
      for k,v in JSON.parse( user.tags || '{}' )
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
      rows.append row
    end

    rows
  end

end