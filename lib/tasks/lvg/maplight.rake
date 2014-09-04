require 'open-uri'

API_KEY = ''

namespace :lvg do

  def fetchFromMaplight(url)
    root = 'http://beta.votersedge.org/services_open_api/'
    url = "#{root}#{url}&apikey=#{API_KEY}"
    pp "Fetching #{url}"
    results = ""
    endpoint = open(url, :http_basic_authentication => ['beta', 'beta']) do |f|
      f.each_line {|line| 
        results = "#{results}#{line}" unless line[0] == '<'
      }
    end 
    JSON.parse(results)
  end

  def ballot(address)
    fetchFromMaplight "cvg.ballot_v1.json?address=#{address}"
  end

  def contest(contest_id, date)
    fetchFromMaplight "cvg.contest_v1.json?contest=#{contest_id}&date=#{date}"
  end

  def measure(measure_id)
    fetchFromMaplight "cvg.measure_v1.json?measure_id=#{measure_id}&data_type=all"
  end

  def candidate(candidate_id)
    fetchFromMaplight "cvg.candidate_v1.json?candidate_id=#{candidate_id}&data_type=all"
  end

  task :import_maplight => :environment do 
    contests = ballot('California')

    contests.keys().each do |contest_id|
      date = contests[contest_id]['election_date']

      pp "parsing contest #{contest_id}"

      if contest_id[0] == 'M'
        measures = contest(contest_id, date)

        measures.keys().each do |measure_id|
          pp "Getting data for measure #{measure_id}"
          measure_data = measure(measure_id)
          #pp measure_data
        end
      elsif contest_id[0] == 'O'
        candidates = contest(contest_id, date)
        candidates.keys().each do |candidate_id|
          pp "Getting data for candidate #{candidate_id}"
          candidate_data = candidate(candidate_id)
          # pp candidate_data
        end
      end

    end
  end

end