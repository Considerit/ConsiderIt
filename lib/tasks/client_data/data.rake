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



task :insert_empty_users => :environment do
  log_level = 'error'
  #host = "localhost:3000"
  host = "tigard.consider.it"
  #proposal_id = '010c97ddc8'

  path = Rails.root.join('lib', 'tasks', 'client_data', 'load_users.casper.coffee')

  sheet = "lib/tasks/client_data/data/empty_profiles.csv"


  pp '***********************************'
  pp "PROCESSING #{sheet}"
  pp '***********************************'

  CSV.foreach( sheet, :headers => true) do |row|

    opts = ['username', 'password'].map { |param| "--#{param}='#{row[param]}'" }.compact.join(' ')
    pp opts

    system "casperjs --verbose --log-level=#{log_level} --host='#{host}' #{opts} #{File.join(path)}"

  end


end


task :load_tigard_data => :environment do
  log_level = 'error'
  host = "localhost:3000"
  host = "chlk.it"
  proposal_id = '010c97ddc8'


  path = Rails.root.join('lib', 'tasks', 'client_data', 'load_points.casper.coffee')

  cnt = {}

  [ ['points.csv', 'true'], ['comments.csv', 'false']  ].each do |sheet|
    pp '***********************************'
    pp "PROCESSING #{sheet[0]}"
    pp '***********************************'

    processed = 0

    CSV.foreach( "lib/tasks/client_data/data/#{sheet[0]}", :headers => true) do |row|

      if !cnt.has_key? row['group']
        cnt[row['group']] = 0
      end

      cnt[row['group']] += 1

      row['user'] = "#{row['group']}-#{cnt[row['group']]}"
      row['is_point'] = sheet[1]
      row['proposal_id'] = proposal_id



      opts = ['nutshell', 'valence', 'proposal_id', 'body', 'stance', 'user', 'group', 'is_point'].map { |param| row[param] && row[param].length > 0 ? "--#{param}='#{row[param]}'" : nil }.compact.join(' ')
      pp opts

      system "casperjs --verbose --log-level=#{log_level} --host='#{host}' #{opts} #{File.join(path)}"

      # processed += 1

      # if processed > 3
      #   break
      # end

    end

  end

  Rake::Task["cache:points"].invoke
  Rake::Task["cache:users"].invoke
  Rake::Task["cache:proposals"].invoke

end


task :export_gsacrd_data => :environment do
  #accounts = ['livingvotersguide']
  accounts = ['gsacrd', 'gsacrd-staff', 'gsacrd-students']

  accounts.each do |identifier|

    account = Account.find_by_identifier identifier

    CSV.open("lib/tasks/client_data/export/#{identifier}-users.csv", "w") do |csv|
      csv << ["username", "email", "date joined", "#points", '#comments', '#opinions']

      account.users.each do |user|
        csv << [user.name, user.email, user.created_at, user.metric_points, user.metric_comments, user.metric_opinions]
      end
    end

    CSV.open("lib/tasks/client_data/export/#{identifier}-points.csv", "w") do |csv|
      csv << ['proposal', 'type', "author", "valence", "summary", "details", 'author_opinion', '#inclusions', '#comments']

      account.points.published.order(:proposal_id).each do |pnt|
        opinion = pnt.user.opinions.find_by_long_id(pnt.proposal.long_id)
        csv << [pnt.proposal.long_id, 'POINT', pnt.hide_name ? 'ANONYMOUS' : pnt.user.email, pnt.is_pro ? 'Pro' : 'Con', pnt.nutshell, pnt.text, opinion ? stance_name(opinion.stance_segment) : '-', pnt.inclusions.count, pnt.comments.count]

        pnt.comments.each do |comment|
          opinion = comment.user.opinions.find_by_long_id(pnt.proposal.long_id)

          csv << [pnt.proposal.long_id, 'COMMENT', comment.user.email, "", comment.body, '', opinion ? stance_name(opinion.stance_segment) : '-', '', '']
        end
      end
    end

  end
end


task :export_proposal_data => :environment do
  long_id = '21457d22da'
  proposal_alias = 'signalize'

  proposal = Proposal.find_by_long_id long_id

  CSV.open("lib/tasks/client_data/export/#{proposal_alias}-users.csv", "w") do |csv|
    csv << ["username", "email", "date joined", "opinion", "#points"]

    proposal.opinions.published.each do |opinion|
      user = opinion.user
      csv << [user.name, user.email, user.created_at, stance_name(opinion.stance_segment), user.points.where(:long_id => long_id).count]
    end
  end

  CSV.open("lib/tasks/client_data/export/#{proposal_alias}-points.csv", "w") do |csv|
    csv << ['proposal', 'type', "author", "valence", "summary", "details", 'author_opinion', '#inclusions', '#comments']

    proposal.points.published.each do |pnt|
      opinion = pnt.user.opinions.find_by_long_id(pnt.proposal.long_id)
      csv << [pnt.proposal.long_id, 'POINT', pnt.hide_name ? 'ANONYMOUS' : pnt.user.email, pnt.is_pro ? 'Pro' : 'Con', pnt.nutshell, pnt.text, opinion ? stance_name(opinion.stance_segment) : '-', pnt.inclusions.count, pnt.comments.count]

      pnt.comments.each do |comment|
        opinion = comment.user.opinions.find_by_long_id(pnt.proposal.long_id)

        csv << [pnt.proposal.long_id, 'COMMENT', comment.user.email, "", comment.body, '', opinion ? stance_name(opinion.stance_segment) : '-', '', '']
      end
    end
  end

end


task :export_proposal_data => :environment do
  long_id = '21457d22da'
  proposal_alias = 'signalize'

  proposal = Proposal.find_by_long_id long_id

  CSV.open("lib/tasks/client_data/export/#{proposal_alias}-users.csv", "w") do |csv|
    csv << ["username", "email", "date joined", "opinion", "#points"]

    proposal.opinions.published.each do |opinion|
      user = opinion.user
      csv << [user.name, user.email, user.created_at, stance_name(opinion.stance_segment), user.points.where(:long_id => long_id).count]
    end
  end

  CSV.open("lib/tasks/client_data/export/#{proposal_alias}-points.csv", "w") do |csv|
    csv << ['proposal', 'type', "author", "valence", "summary", "details", 'author_opinion', '#inclusions', '#comments']

    proposal.points.published.each do |pnt|
      opinion = pnt.user.opinions.find_by_long_id(pnt.proposal.long_id)
      csv << [pnt.proposal.long_id, 'POINT', pnt.hide_name ? 'ANONYMOUS' : pnt.user.email, pnt.is_pro ? 'Pro' : 'Con', pnt.nutshell, pnt.text, opinion ? stance_name(opinion.stance_segment) : '-', pnt.inclusions.count, pnt.comments.count]

      pnt.comments.each do |comment|
        opinion = comment.user.opinions.find_by_long_id(pnt.proposal.long_id)

        csv << [pnt.proposal.long_id, 'COMMENT', comment.user.email, "", comment.body, '', opinion ? stance_name(opinion.stance_segment) : '-', '', '']
      end
    end
  end

end
