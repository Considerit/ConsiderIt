require 'csv'
require 'pp'

def stance_name(stance_segment)
  case stance_segment
    when 0
      return "strong oppose"
    when 1
      return "oppose"
    when 2
      return "weak oppose"
    when 3
      return "undecided"
    when 4
      return "weak support"
    when 5
      return "support"
    when 6
      return "strong support"
  end
end


task :export_gsacrd_data => :environment do
  #subdomains = ['livingvotersguide']
  subdomains = ['gsacrd', 'gsacrd-staff', 'gsacrd-students']

  subdomains.each do |name|

    subdomain = Subdomain.find_by_name name

    CSV.open("lib/tasks/client_data/export/#{name}-users.csv", "w") do |csv|
      csv << ["username", "email", "date joined", "#points", '#comments', '#opinions']

      subdomain.users.each do |user|
        csv << [user.name, user.email, user.created_at, user.metric_points, user.metric_comments, user.metric_opinions]
      end
    end

    CSV.open("lib/tasks/client_data/export/#{name}-points.csv", "w") do |csv|
      csv << ['proposal', 'type', "author", "valence", "summary", "details", 'author_opinion', '#inclusions', '#comments']

      subdomain.points.published.order(:proposal_id).each do |pnt|
        opinion = pnt.user.opinions.find_by_slug(pnt.proposal.slug)
        csv << [pnt.proposal.slug, 'POINT', pnt.hide_name ? 'ANONYMOUS' : pnt.user.email, pnt.is_pro ? 'Pro' : 'Con', pnt.nutshell, pnt.text, opinion ? stance_name(opinion.stance_segment) : '-', pnt.inclusions.count, pnt.comments.count]

        pnt.comments.each do |comment|
          opinion = comment.user.opinions.find_by_slug(pnt.proposal.slug)

          csv << [pnt.proposal.slug, 'COMMENT', comment.user.email, "", comment.body, '', opinion ? stance_name(opinion.stance_segment) : '-', '', '']
        end
      end
    end

  end
end


task :export_proposal_data => :environment do
  slug = '21457d22da'
  proposal_alias = 'signalize'

  proposal = Proposal.find_by_slug slug

  CSV.open("lib/tasks/client_data/export/#{proposal_alias}-users.csv", "w") do |csv|
    csv << ["username", "email", "date joined", "opinion", "#points"]

    proposal.opinions.published.each do |opinion|
      user = opinion.user
      csv << [user.name, user.email, user.created_at, stance_name(opinion.stance_segment), user.points.where(:slug => slug).count]
    end
  end

  CSV.open("lib/tasks/client_data/export/#{proposal_alias}-points.csv", "w") do |csv|
    csv << ['proposal', 'type', "author", "valence", "summary", "details", 'author_opinion', '#inclusions', '#comments']

    proposal.points.published.each do |pnt|
      opinion = pnt.user.opinions.find_by_slug(pnt.proposal.slug)
      csv << [pnt.proposal.slug, 'POINT', pnt.hide_name ? 'ANONYMOUS' : pnt.user.email, pnt.is_pro ? 'Pro' : 'Con', pnt.nutshell, pnt.text, opinion ? stance_name(opinion.stance_segment) : '-', pnt.inclusions.count, pnt.comments.count]

      pnt.comments.each do |comment|
        opinion = comment.user.opinions.find_by_slug(pnt.proposal.slug)

        csv << [pnt.proposal.slug, 'COMMENT', comment.user.email, "", comment.body, '', opinion ? stance_name(opinion.stance_segment) : '-', '', '']
      end
    end
  end

end

task :export_all_comments => :environment do
  subdomain = Subdomain.find_by_name('tigard')

  CSV.open("lib/tasks/client_data/export/#{subdomain.name}-opinions.csv", "w") do |csv|
    csv << ["proposal", "username", "email", "date joined", "opinion", "#points"]
  end

  CSV.open("lib/tasks/client_data/export/#{subdomain.name}-points.csv", "w") do |csv|
    csv << ['proposal', 'type', "author", "valence", "summary", "details", 'author_opinion', '#inclusions', '#comments']
  end

  subdomain.proposals.each do |proposal|

    CSV.open("lib/tasks/client_data/export/#{subdomain.name}-opinions.csv", "a") do |csv|
      proposal.opinions.published.each do |opinion|
        user = opinion.user
        csv << [proposal.slug, user.name, user.email.gsub('.ghost', ''), user.created_at, opinion.stance, user.points.where(:proposal_id => proposal.id).count]
      end
    end

    CSV.open("lib/tasks/client_data/export/#{subdomain.name}-points.csv", "a") do |csv|

      proposal.points.published.each do |pnt|
        opinion = pnt.user.opinions.find_by_proposal_id(pnt.proposal.id)
        csv << [pnt.proposal.slug, 'POINT', pnt.hide_name ? 'ANONYMOUS' : pnt.user.email.gsub('.ghost', ''), pnt.is_pro ? 'Pro' : 'Con', pnt.nutshell, pnt.text, opinion ? stance_name(opinion.stance_segment) : '-', pnt.inclusions.count, pnt.comments.count]

        pnt.comments.each do |comment|
          opinion = comment.user.opinions.find_by_proposal_id(pnt.proposal.id)
          csv << [pnt.proposal.slug, 'COMMENT', comment.user.email.gsub('.ghost', ''), "", comment.body, '', opinion ? opinion.stance : '-', '', '']
        end
      end
    end
  end

end
