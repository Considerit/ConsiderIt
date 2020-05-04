def stats(vals)

  total_score = 0
  avg_score = 0 
  std_dev = 0

  if vals.length > 0
    total_score = vals.sum
    avg_score = total_score / vals.length
    differences = vals.sum {|v| (v - avg_score)**2}
    std_dev = vals.length > 0 ? (differences/vals.length)**0.5 : 0
  end

  {
    total: total_score,
    avg: avg_score,
    std_dev: std_dev,
    count: vals.length
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
    rows = []
    heading = ['slug', 'url', 'created', "username", "author", 'name', 'category', 'description', '#points', '#opinions', 'total score', 'avg score', 'std deviation']

    if SPECIAL_GROUPS.has_key?(subdomain.name.downcase)
      SPECIAL_GROUPS[subdomain.name.downcase].each do |group|
        heading.append("#{group[:label] || group[:tag]} opinions")
        heading.append("difference")
      end 
    end
    rows.append heading 

    subdomain.proposals.each do |proposal|
      opinions = proposal.opinions.published

      s = stats opinions.map{|o| o.stance}

      row = [proposal.slug, "https://#{subdomain.host_with_port}/#{proposal.slug}", proposal.created_at, proposal.user.name, proposal.user.email.gsub('.ghost', ''), proposal.name, (proposal.cluster || 'Proposals'), proposal.description, proposal.points.published.count, opinions.count, s[:total].round(2), s[:avg].round(2), s[:std_dev].round(2)]
      group_diffs = group_differences proposal 
      group_diffs.each do |diff|
        row.append diff[:ingroup][:count]
        row.append diff[:diff].round(2)
      end
      rows.append row
    end

    rows
  end

  def users(subdomain, tag_whitelist)
    fname = "#{subdomain.name}-users"

    heading = ['email', 'name', 'date joined'] 

    if tag_whitelist
      tag_whitelist.each do |tag|
        heading.append tag.split('.')[0]
      end
    end

    rows = []
    rows.append heading 

    subdomain.users.each do |user|
      
      row = [user.email, user.name, user.created_at]

      if tag_whitelist
        user_tags = JSON.parse( user.tags || '{}' )

        tag_whitelist.each do |tag|
          row.append user_tags.has_key?(tag) ? user_tags[tag] : ""
        end 
      end 

      rows.append row

    end

    rows
  end

end


def group_differences(proposal)

  subdomain = proposal.subdomain
  return [] if !SPECIAL_GROUPS.has_key?(subdomain.name.downcase)

  groups = SPECIAL_GROUPS[subdomain.name.downcase]
  differences = []
  groups.each do |group|
    in_group = []
    out_group = []

    proposal.opinions.published.each do |o|
      if passes_tag(o.user, group[:tag])
        in_group.append(o.stance) 
      else 
        out_group.append(o.stance)
      end
    end

    sin = stats in_group
    sout = stats out_group

    differences.append({
      group: group,
      ingroup: sin, 
      outgroup: sout,
      diff: sin[:count] > 0 ? sin[:avg] - sout[:avg] : 0
    })

  end

  differences
end

USER_TAGS = {}
def passes_tag(user, tag)
  if !USER_TAGS.has_key?(user.id)
    USER_TAGS[user.id] = Oj.load(user.tags || '{}')
  end

  tags = USER_TAGS[user.id]
  tags.has_key?(tag) && !['no', 'false'].include?("#{tags[tag]}".downcase)
end

SPECIAL_GROUPS = {
  'newblueplan' => [{
      label: 'Elected Dem. Leader',
      tag: 'elected_wa-dems.editable'
    }, {
      label: 'Precinct Committee Officer',
      tag: 'pco_wa-dems.editable'
    }, {
      label: 'Dem. Volunteer',
      tag: 'volunteer_wa-dems.editable'
    }, {
      label: 'Dem. Donor',
      tag: 'donor_wa-dems.editable'
    }, {
      label: 'Civic Org. Leader',
      tag: 'ledcivic_wa-dems.editable'
    }, {
      label: 'Civic Org. Volunteer',
      tag: 'volcivic_wa-dems.editable'
    }, {
      label: 'Civic Org. Staff',
      tag: 'civic_staff_wa-dems.editable'
    }, {
      label: 'Dem. Party Staff',
      tag: 'staff_wa-dems.editable'
    }]

}