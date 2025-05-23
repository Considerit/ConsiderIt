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

def get_identity(user, subdomain, anonymize)
  if !user
    return ['Unknown', 'Unknown']
  end

  if subdomain.name.start_with?('smart-home-dialogue-')
    tags = user.tags || {}
    user_name = user_email = tags.fetch("#{subdomain.name}-what-is-your-prolific-id", "no-id-given")
  elsif !anonymize
    user_name = user.name
    user_email = user.email.gsub('.ghost', '')
  else 
    info = User.anonymized_info(user.id, subdomain, true)
    user_name = info["name"] 
    user_email = info["email"] + "#{User.anonymized_id(user.id)}"      
  end
  [user_name, user_email]
end

module DataExports

  def DataExports.opinions(subdomain)
    fname = "#{subdomain.name}-opinions"
    heading = ["proposal_slug","proposal_name", 'created_at', "username", "email", "opinion", "#points"]
    rows = []
    rows.append heading 
    anonymize_permanently = subdomain.customization_json['anonymize_permanently']

    subdomain.proposals.each do |proposal|

      proposal.opinions.published.each do |opinion|
        user = opinion.user
        anonymize_opinion = anonymize_permanently || opinion.hide_name

        user_name, user_email = get_identity(user, subdomain, anonymize_opinion)

        begin 
          rows.append [proposal.slug, proposal.name, opinion.created_at, user_name, user_email, opinion.stance, user.points.where(:proposal_id => proposal.id).count]
        rescue 
        end 
      end

    end

    rows
  end

  def DataExports.inclusions(subdomain)
    fname = "#{subdomain.name}-inclusions"
    heading = ["proposal_slug","proposal_name", 'created_at', "username", "email", "opinion_on_proposal", "valence", "point",  "is_author"]
    rows = []
    rows.append heading 
    anonymize_permanently = subdomain.customization_json['anonymize_permanently']

    subdomain.proposals.each do |proposal|

      proposal.opinions.published.each do |opinion|
        user = opinion.user
        anonymize_opinion = anonymize_permanently || opinion.hide_name

        user_name, user_email = get_identity(user, subdomain, anonymize_opinion)

        (opinion.point_inclusions or []).each do |point_id|
          begin 
            pnt = Point.find(point_id)
            rows.append [proposal.slug, proposal.name, opinion.created_at, user_name, user_email, opinion.stance, pnt.is_pro ? 'Pro' : 'Con', pnt.nutshell, opinion.user_id==pnt.user_id ]
          rescue 
          end 
        end
      end

    end

    rows
  end

  def DataExports.points(subdomain)
    fname = "#{subdomain.name}-points"
    heading = ['proposal_slug', 'proposal_name', 'type', 'created_at', "username", "email", "valence", "summary", "details", 'author_opinion', '#inclusions', '#comments']
    rows = []
    rows.append heading 
    anonymize_permanently = subdomain.customization_json['anonymize_permanently']

    subdomain.proposals.each do |proposal|
      proposal.points.published.each do |pnt|
        begin 
          if [nil, 1].include?(pnt.moderation_status)
            opinion = pnt.user.opinions.find_by_proposal_id(pnt.proposal.id)
            anonymize_point = anonymize_permanently || opinion.hide_name || pnt.hide_name

            pnt_user_name, pnt_user_email = get_identity(pnt.user, subdomain, anonymize_point)

            rows.append [pnt.proposal.slug, pnt.proposal.name, 'POINT', pnt.created_at, pnt_user_name, pnt_user_email, pnt.is_pro ? 'Pro' : 'Con', pnt.nutshell, pnt.text, opinion ? opinion.stance : '-', pnt.inclusions.count, pnt.comments.count]

            pnt.comments.each do |comment|
              if [nil, 1].include?(comment.moderation_status)
                opinion = comment.user.opinions.find_by_proposal_id(pnt.proposal.id)

                anonymize_comment = anonymize_permanently || comment.hide_name            
                comment_user_name, comment_user_email = get_identity(comment.user, subdomain, anonymize_comment)

                rows.append [pnt.proposal.slug, pnt.proposal.name, 'COMMENT', comment.created_at, comment_user_name, comment_user_email, "", comment.body, '', opinion ? opinion.stance : '-', '', '']
              end
            end
          end
        rescue 
        end 
      end
    end

    rows
  end

  def DataExports.proposals(subdomain)
    fname = "#{subdomain.name}-proposals"
    rows = []
    heading = ['proposal_slug', 'forum_url', 'created_at', "username", "email", 'title', 'category', 'description', '#points', '#opinions', 'total score', 'avg score', 'std deviation']
    anonymize_permanently = subdomain.customization_json['anonymize_permanently']
    

    if SPECIAL_GROUPS.has_key?(subdomain.name.downcase)

      super_heading = []
      heading.each do |head|
        super_heading.append ""
      end 

      SPECIAL_GROUPS[subdomain.name.downcase].each do |group|
        group[:vals].each do |val|
          super_heading = super_heading.concat ["#{group[:label] || group[:tag]}-#{val}", "", ""]
          heading.append("#opinions")
          heading.append("avg score")
          heading.append("difference w/ rest")
        end 
      end 

      rows.append super_heading

    end

    rows.append heading 

    subdomain.proposals.each do |proposal|
      if [nil, 1].include?(proposal.moderation_status)

        opinions = proposal.opinions.published

        s = stats opinions.map{|o| o.stance}
        
        user_name, user_email = get_identity(proposal.user, subdomain, anonymize_permanently || proposal.hide_name)

        row = [proposal.slug, "https://#{subdomain.url}/#{proposal.slug}", proposal.created_at, user_name, user_email, proposal.name, (proposal.cluster || 'Proposals'), proposal.description, proposal.points.published.count, opinions.count, s[:total].round(2), s[:avg].round(2), s[:std_dev].round(2)]
        group_diffs = group_differences proposal 
        group_diffs.each do |diff|
          row.append diff[:ingroup][:count]
          row.append diff[:ingroup][:avg].round(2)
          row.append diff[:diff].round(2)
        end
        rows.append row
      end
    end

    rows
  end

  def DataExports.users(subdomain, tag_whitelist)
    fname = "#{subdomain.name}-users"

    heading = ['email', 'username', 'date joined'] 
    anonymize_permanently = subdomain.customization_json['anonymize_permanently']
    anonymization_safe_opinion_filters = subdomain.customization_json['anonymization_safe_opinion_filters']
    export_tags = !anonymize_permanently || anonymization_safe_opinion_filters

    heading.append '#_opinions_given'

    if export_tags && tag_whitelist
      tag_whitelist.each do |tag|
        heading.append tag
      end

    end


    groups = SPECIAL_GROUPS[subdomain.name.downcase]
    if groups 
      groups.each do |g|
        if g[:proposal_id]
          heading.append g[:label]
        end 
      end
    end 

    rows = []
    rows.append heading 

    subdomain.users.each do |user|
      
      user_name, user_email = get_identity(user, subdomain, anonymize_permanently)

      if subdomain.name.start_with?("smart-home-dialogue-")
        num_opinions = user.opinions.where(:subdomain_id => subdomain.id).count
      else
        num_opinions = user.opinions.where(:subdomain_id => subdomain.id, :hide_name => false).count
      end

      row = [user_email, user_name, user.created_at, num_opinions]

      if export_tags && tag_whitelist
        user_tags = user.tags || {}

        tag_whitelist.each do |tag|
          row.append user_tags.fetch(tag, "")
        end 
        
      end 

      if groups
        groups.each do |g|
          if g[:proposal_id]
            o = opinion_for_proposal(user, g[:proposal_id])
            if !o || !o.published
              row.append ""
            else
              row.append o.stance.round(2)
            end  
          end 
        end
      end 

      rows.append row

    end

    rows
  end

end


def opinion_for_proposal(user, proposal_id)
  user.opinions.published.find_by_proposal_id(proposal_id)
  Proposal.find(proposal_id).opinions.find_by_user_id(user.id)
end 

def group_differences(proposal)

  subdomain = proposal.subdomain
  return [] if !SPECIAL_GROUPS.has_key?(subdomain.name.downcase)

  groups = SPECIAL_GROUPS[subdomain.name.downcase]
  differences = []
  groups.each do |group|

    group[:vals].each do |val|

      in_group = []
      out_group = []

      proposal.opinions.published.each do |o|

        if group[:proposal_id] 
          o = opinion_for_proposal(o.user, group[:proposal_id])
          next if !o || !o.published

          if val
            passes = o.stance > 0
          else 
            passes = o.stance < 0
          end 

        else 
          passes = passes_val(o.user, group[:tag], val)
        end 

        if passes
          in_group.append(o.stance) 
        else 
          out_group.append(o.stance)
        end
      end

      sin = stats in_group
      sout = stats out_group

      differences.append({
        group: group,
        val: val,
        ingroup: sin, 
        outgroup: sout,
        diff: sin[:count] > 0 ? sin[:avg] - sout[:avg] : 0
      })
    end
  end

  differences
end

USER_TAGS = {}
def passes_val(user, tag, val)
  if !USER_TAGS.has_key?(user.id)
    USER_TAGS[user.id] = user.tags || {}
  end

  tags = USER_TAGS[user.id]
  tags.has_key?(tag) && tags[tag].downcase == val.downcase
end

SPECIAL_GROUPS = {


  'denverclimateaction' => [
    {
      label: "Agrees with urgency of climate action",
      proposal_id: 14653,
      vals: [true, false]
    },
    {
      label: "Agrees with equity aspect of TF goal",
      proposal_id: 14654,
      vals: [true, false]
    },
    {
      label: "racethnicity",
      tag: 'denverclimateaction-racethnicity',
      vals: ['White',"Hispanic or Latinx","Black or African American","Asian or Asian American","American Indian or Alaska Native","Native Hawaiian or other Pacific Islander","Multiple Races","Prefer not to answer"]
    }, 
    {
      label: "income",
      tag: 'denverclimateaction-income',
      vals: ['Less than $10,000', '$10,000-$49,999', '$50,000 - $99,999', '$100,000 - $149,999', '$150,000+', 'Prefer not to answer'] 
    }
  ],

  'newblueplan' => [{
      label: 'Elected Dem. Leader',
      tag: 'elected_wa-dems'
    }, {
      label: 'Precinct Committee Officer',
      tag: 'pco_wa-dems'
    }, {
      label: 'Dem. Volunteer',
      tag: 'volunteer_wa-dems'
    }, {
      label: 'Dem. Donor',
      tag: 'donor_wa-dems'
    }, {
      label: 'Civic Org. Leader',
      tag: 'ledcivic_wa-dems'
    }, {
      label: 'Civic Org. Volunteer',
      tag: 'volcivic_wa-dems'
    }, {
      label: 'Civic Org. Staff',
      tag: 'civic_staff_wa-dems'
    }, {
      label: 'Dem. Party Staff',
      tag: 'staff_wa-dems'
    }]

}
