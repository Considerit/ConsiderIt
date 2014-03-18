require 'csv'
require 'pp'

host = "localhost:3000"
host = "chlk.it"
proposal_id = '010c97ddc8'

log_level = 'error'
task :load_tigard_data => :environment do
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

