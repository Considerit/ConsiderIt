require 'open-uri'
include ActionView::Helpers::NumberHelper

MAPLIGHT_API_KEY = '1e6bae2f57efdf70d3bc198bd6b89869'

namespace :lvg do

  def fetchFromMaplight(url)
    root = 'http://votersedge.org/services_open_api/'
    url = "#{root}#{url}&apikey=#{MAPLIGHT_API_KEY}"
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
    contests = ballot('Washington')

    contests.keys().each do |contest_id|
      date = contests[contest_id]['election_date']

      pp "parsing contest #{contest_id}"

      if contest_id[0] == 'M'
        measures = contest(contest_id, date)
        measures.keys().each do |measure_id|
          pp "Getting data for measure #{measure_id}"
          measure_data = measure(measure_id)
          if measure_id == '117'
            loadMeasureData measure_data
          end
          #pp measure_data
        end
      elsif contest_id[0] == 'O'
        candidates = contest(contest_id, date)

        candidates.keys().each do |candidate_id|
          pp "Getting data for candidate #{candidate_id}"
          candidate_data = candidate(candidate_id)
          pp "...got for #{candidate_data['contest']['title']}"

          #loadCandidateData candidate_data
          # pp candidate_data
        end
      end

    end
  end

  task :go => :environment do 
    loadMeasureData(example_measure_data)
    #loadCandidateData(example_candidate_data)
  end


  def loadCandidateData(data)
    ["politician_id",
     "candidate_id",
     "display_name",
     "original_name",
     "gender",
     "first_name",
     "middle_name",
     "last_name",
     "name_prefix",
     "name_suffix",
     "bio",
     "party",
     "candidate_flags",
     "last_funding_update",
     "roster_name",
     "url",
     "summary",
     "funding",
     "multimedia",
     "contest",
     "type"]

    pp data
    pp data['display_name'], data['original_name'], data['roster_name'], data['bio'], data['party'], data['candidate_flags'], data['type']


  end

  def loadMeasureData(data)

    long_id = "#{data['identifier']}_#{data['topic'].gsub(' ', '_')}"
    p = Proposal.where(:long_id => long_id).first
    if p.nil?
      p = Proposal.new({
              :user_id => 1,
              :account_id => 1,
              :long_id => long_id,
              :name => data['maplight_title'],
              :description => data['summary']['main_summary'],
              :publicity => 1
            })
    end

    funding_html = ""
    endorsement_html = ""
    editorial_html = ""
    news_html = ""

    [ data['funding']['support'], data['funding']['oppose'] ].each_with_index do |funders, idx|
      endorser_type = "The #{idx == 0 ? 'YES' : 'NO'} campaign has raised #{number_to_currency(funders['grand_total'])}"
      funding_html += "<div class='endorser_group funders #{idx == 0 ? 'support' : 'oppose'}'><div>#{endorser_type}</div><ul>"

      for funder in funders['items'][0..10]
        funding_html += "<li><span class='funder_name'>#{funder['name']}</span><span class='funder_amount'>#{number_to_currency(funder['amount'])}</span></li>"
      end
      if funders['items'].length > 10
        funding_html += "<li class='other_donors'>...#{funders['items'].length - 10} other donors</li>"
      end
      funding_html += "</ul></div>"
    end

    [ data['endorsements']['support'], data['endorsements']['oppose'] ].each_with_index do |endorsers, idx|
      endorser_type = idx == 0 ? 'This measure is endorsed by:' : 'This measure is opposed by:' 
      endorsement_html += "<div class='endorser_group endorsements #{idx == 0 ? 'support' : 'oppose'}'><div>#{endorser_type}</div><p>"
      for endorsement in endorsers
        endorsement_html += "<a href='#{endorsement['url']}' rel='nofollow' target='_blank' style='text-decoration:underline'>#{endorsement['title']}</a>, "
      end
      endorsement_html = endorsement_html[0..endorsement_html.length-3]
      endorsement_html += "</p></div>"
    end

    [ data['editorials']['support'], data['editorials']['oppose'] ].each_with_index do |editorials, idx|
      endorser_type = idx == 0 ? 'Supporting this measure:' : 'Opposing this measure:' 
      editorial_html += "<div class='endorser_group editorials #{idx == 0 ? 'support' : 'oppose'}'><div>#{endorser_type}</div><ul>"
      for editorial in editorials
        editorial_html += "<li><a href='#{editorial['url']}' rel='nofollow' target='_blank' style='text-decoration:underline'>#{editorial['headline']}</a>, #{editorial['outlet']}, #{editorial['date']}</li>"
      end
      editorial_html += "</ul></div>"
    end

    news_html += "<ul class='news'>"
    stories = data['news']
    stories.delete 'source'
    for story in data['news'].values()
      news_html += "<li><a href='#{story['url']}' rel='nofollow' target='_blank' style='text-decoration:underline'>#{story['headline']}</a>, #{story['outlet']}, #{story['date']}</li>"
    end
    news_html += "</ul>"


    description_fields = [
      {
        :group => "Who supports each side?",
        :items => [{:label => 'Who is endorsing and funding each side?', :html => "<div>#{funding_html}</div><div>#{endorsement_html}</div>"}, {:label => 'Editorials', :html => editorial_html}]
      },
      {
        :group => "Media coverage",
        :items => [{:label => 'News stories and debates', :html => news_html}]
      }
    ]

    

    p.description_fields = JSON.dump description_fields

    pp long_id
    p.save

  end

end

