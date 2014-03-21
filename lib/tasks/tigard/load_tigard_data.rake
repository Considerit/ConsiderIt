require 'csv'
require 'pp'

task :load_tigard_data => :environment do
  log_level = 'error'
  host = "localhost:3000"
  host = "chlk.it"
  proposal_id = '010c97ddc8'


  path = Rails.root.join('lib', 'tasks', 'tigard', 'load_points.casper.coffee')

  cnt = {}

  [ ['points.csv', 'true'], ['comments.csv', 'false']  ].each do |sheet|
    pp '***********************************'
    pp "PROCESSING #{sheet[0]}"
    pp '***********************************'

    processed = 0

    CSV.foreach( "lib/tasks/tigard/data/#{sheet[0]}", :headers => true) do |row|

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


task :export_tigard_data => :environment do
  #accounts = ['livingvotersguide']
  accounts = ['gsacrd', 'gsacrd-staff', 'gsacrd-students']

  accounts.each do |identifier|

    account = Account.find_by_identifier identifier

    CSV.open("lib/tasks/tigard/export/#{identifier}-users.csv", "w") do |csv|
      csv << ["username", "email", "date joined", "#points", '#comments', '#opinions']

      account.users.each do |user|
        csv << [user.name, user.email, user.created_at, user.metric_points, user.metric_comments, user.metric_opinions]
      end
    end

    CSV.open("lib/tasks/tigard/export/#{identifier}-points.csv", "w") do |csv|
      csv << ['proposal', 'type', "author", "valence", "summary", "details", 'author_opinion', '#inclusions', '#comments']

      account.points.published.order(:proposal_id).each do |pnt|
        opinion = pnt.user.opinions.find_by_long_id(pnt.proposal.long_id)
        csv << [pnt.proposal.long_id, 'POINT', pnt.hide_name ? 'ANONYMOUS' : pnt.user.email, pnt.is_pro ? 'Pro' : 'Con', pnt.nutshell, pnt.text, opinion ? opinion.stance_name : '-', pnt.inclusions.count, pnt.comments.count]

        pnt.comments.each do |comment|
          opinion = comment.user.opinions.find_by_long_id(pnt.proposal.long_id)

          csv << [pnt.proposal.long_id, 'COMMENT', comment.user.email, "", comment.body, '', opinion ? opinion.stance_name : '-', '', '']
        end
      end


    end

  end
end
