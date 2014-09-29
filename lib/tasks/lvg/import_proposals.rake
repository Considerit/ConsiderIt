require 'csv'
require 'pp'

year = "2014"

def parse(html)
  #HTML::WhiteListSanitizer.allowed_css_properties = Set.new(%w(text-align font-weight text-decoration font-style))
  parsed = ActionController::Base.helpers.sanitize(html.encode!('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: ''), tags: %w(table tr td div p br label ul li ol span strong h1 h2 h3 h4 h5), attributes: %w(id colspan) )  
  parsed = parsed.gsub('<p>&nbsp;</p>', '')
end


# maps from considerit long_ids to maplight measure/candidate ids
maplight_hash = {
  'I-522_Require_labels_on_GMO_foods' => '117',
  'I-517_Modify_initiative_processes' => '116',
  'I-591_Match_state_gun_regulation_to_national_standards' => '541',
  'I-594_Increase_background_checks_on_gun_purchases' => '540',
  'I-1351_Modify_K-12_funding' => '542'
}

MAPLIGHT_API_KEY = '1e6bae2f57efdf70d3bc198bd6b89869'

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

def fetchAndParseMeasureFromMaplight(measure_id)
  data = fetchFromMaplight "cvg.measure_v1.json?measure_id=#{measure_id}&data_type=all"
  
  funding_html = ""
  endorsement_html = ""
  editorial_html = ""
  news_html = ""

  if data['funding'] && ( (data['funding']['oppose'] && data['funding']['oppose']['items'] != nil) || (data['funding']['support'] && data['funding']['support']['items'] != nil) )
    [ data['funding']['support'], data['funding']['oppose'] ].each_with_index do |funders, idx|

      if funders && funders['items'] && funders['items'].length > 0

        endorser_type = "Donations in #{idx == 0 ? 'Support' : 'Opposition'} <span class='total_money_raised'>#{number_to_currency(funders['grand_total'], :precision => 0)}</span>"
        funding_html += "<div class='endorser_group funders #{idx == 0 ? 'support' : 'oppose'}'><div>#{endorser_type}</div><ul>"
      
        for funder in funders['items'][0..10]
          funding_html += "<li><span class='funder_name'>#{funder['name'].split.map(&:capitalize).join(' ').gsub('Llc', 'LLC')}</span><span class='funder_amount'>#{number_to_currency(funder['amount'], :precision => 0)}</span></li>"
        end
        if funders['items'].length > 10
          funding_html += "<li class='other_donors'>...#{funders['items'].length - 10} other donors</li>"
        end
      else
        funding_html += "<div style='font-style: italic'>No donations in #{idx == 0 ? 'Support' : 'Opposition'} yet</div><ul>"
      end
      funding_html += "</ul></div>"
    end
  end

  
  if data['endorsements'] && ((data['endorsements']['support'] != [nil] && data['endorsements']['support'].length > 0) || (data['endorsements']['oppose'] != [nil] && data['endorsements']['oppose'].length > 0))
    [ data['endorsements']['support'], data['endorsements']['oppose'] ].each_with_index do |endorsers, idx|
      
      endorser_type = idx == 0 ? 'This measure is endorsed by:' : 'This measure is opposed by:' 
      endorsement_html += "<div class='endorser_group endorsements #{idx == 0 ? 'support' : 'oppose'}'><div>#{endorser_type}</div><p>"
      if endorsers.length == 0 || endorsers == [nil]
        endorsement_html += "<span style='font-style: italic'>No endorsers yet</span>"
      else
        for endorsement in endorsers
          endorsement_html += "<a href='#{endorsement['url']}' rel='nofollow' target='_blank' style='text-decoration:underline'>#{endorsement['title']}</a>, "
        end
        endorsement_html = endorsement_html[0..endorsement_html.length-3]
      end
      endorsement_html += "</p></div>"
    end
  end

  if data['editorials'] && ((data['editorials']['support'] && data['editorials']['support'].length > 0) || (data['editorials']['oppose'] && data['editorials']['oppose'].length > 0))
    [ data['editorials']['support'], data['editorials']['oppose'] ].each_with_index do |editorials, idx|
      endorser_type = idx == 0 ? 'Supporting this measure:' : 'Opposing this measure:' 
      editorial_html += "<div class='endorser_group editorials #{idx == 0 ? 'support' : 'oppose'}'><div>#{endorser_type}</div><ul>"
      if (editorials && editorials.length > 0)
        for editorial in editorials
          editorial_html += "<li><a href='#{editorial['url']}' rel='nofollow' target='_blank' style='text-decoration:underline'>#{editorial['headline']}</a><br>#{editorial['outlet']}, #{editorial['date']}</li>"
        end
      else
        editorial_html += "<li style='font-style: italic'>None written yet</li>"
      end
      editorial_html += "</ul></div>"
    end
  end

  if data['news'] 
    stories = data['news']
    stories.delete 'source'
    if stories.values().length > 0  
      news_html += "<ul class='news'>"
      for story in data['news'].values()
        news_html += "<li><a href='#{story['url']}' rel='nofollow' target='_blank' style='text-decoration:underline'>#{story['headline']}</a><br>#{story['outlet']}, #{story['date']}</li>"
      end
      news_html += "</ul>"
    end
  end
  description_fields = []

  if funding_html + endorsement_html + editorial_html != ""
    group = ({
      :group => "Who supports each side?",
      :items => []
    })

    if funding_html + endorsement_html != ""
      group[:items].append({
              :label => 'Funding and endorsements', 
              :html => "<div>#{funding_html}</div><div>#{endorsement_html}</div>"
            })
    end

    if editorial_html != ""
      group[:items].append({
              :label => 'Editorials', 
              :html => editorial_html
            })
    end

    description_fields.append group

  end

  if news_html != ''
    description_fields.append({
      :group => "Media coverage",
      :items => [{:label => 'News stories and debates', :html => news_html}]
    })
  end


  return [data['summary']['main_summary'], description_fields]

end


namespace :lvg do

  task :import_candidates => :environment do
    account = Account.find_by_identifier('livingvotersguide')

    candidates = [1051, 5136, 5222, 1020, 1228, 1173, 5220, 1005, 1094, 5215, 1185, 1227, 4878, 5138, 1273, 1191, 5206, 997, 5134, 1052] # maplight candidate ids

    candidates.each do |candidate_id|
      data = fetchFromMaplight("cvg.candidate_v1.json?candidate_id=#{candidate_id}&data_type=all")
      jurisdiction = data['contest']['title'].gsub(' - Washington', '')
      name = data['display_name']
      long_id = "#{name}-washington_#{jurisdiction}".gsub(' ', '_').downcase

      # pp data['summary']['summary_items'].map {|i| i.keys()}
      #pp jurisdiction, name, long_id

      contest_description = "U.S. #{data['contest']['office']['body']}"
      gender = data['gender'] == 'F' ? 'Her' : 'His'

      description = "#{name} is a #{data['party']} candidate seeking to represent Washington's #{jurisdiction} in the #{contest_description}."

      description_fields = data['summary']['summary_items'].map {|item| {:label => item['title'].downcase.capitalize, :html => item['yes_text'].gsub('Not Applicable', 'None found')} }

      funding_html = ""

      if data['funding'] &&  (data['funding']['support'] && data['funding']['support']['items'] != nil)
        funders = data['funding']['support']

        if funders && funders['items'] && funders['items'].length > 0

          endorser_type = "<span style='float:none' class='total_money_raised'>#{number_to_currency(funders['grand_total'], :precision => 0)}</span>"
          funding_html += "<div class='funders support'><div style='text-align: right'>#{endorser_type}</div><ul>"
        
          for funder in funders['items'][0..10]
            funding_html += "<li><span class='funder_name'>#{funder['name'].split.map(&:capitalize).join(' ').gsub('Llc', 'LLC')}</span><span class='funder_amount'>#{number_to_currency(funder['amount'], :precision => 0)}</span></li>"
          end
          if funders['items'].length > 10
            funding_html += "<li class='other_donors'>...#{funders['items'].length - 10} other donors</li>"
          end
        else
          funding_html += "<div style='font-style: italic'>No donations in Support yet</div><ul>"
        end
        funding_html += "</ul></div>"
      end

      
      if funding_html != ""
        description_fields.append({
                  :label => 'Donors', 
                  :html => "<div>#{funding_html}</div>"
                })
      end


      measure = {
        :account_id => account.id,
        :user_id => 1, 
        :long_id => long_id,
        :name => name,
        :description => description,
        :published => true, #TODO: make configurable

        :cluster => jurisdiction,
        :description_fields => description_fields.length > 0 ? JSON.dump(description_fields) : nil,

        # :url1 => row.fetch('url', nil),

        :seo_title => "#{name}, Candidate for Washington #{jurisdiction}",
        :seo_description => description,
        :seo_keywords => "washington,state,us,congressional,2014,#{name}"
      }

      #proposal = Proposal.find_by_long_id long_id
      proposal = Proposal.find_by_long_id long_id
      if !proposal
        proposal = Proposal.new measure
        proposal.save
        pp "Added #{long_id}"
      else
        measure.delete :account_id
        proposal.update_attributes measure
        pp "Updated #{long_id}"        
      end

    end


  end

  task :import_proposals => :environment do
    account = Account.find_by_identifier('livingvotersguide')

    CSV.foreach("lib/tasks/lvg/#{year}/measures.csv", :headers => true, :encoding => 'windows-1251:utf-8') do |row|
      jurisdiction = row['jurisdiction'].split.map(&:capitalize).join(' ')

      long_id = row['topic']
      if row['category'] && row['designator']
        long_id = "#{row['category'][0]}-#{row['designator']}_#{long_id}"
      end

      if jurisdiction != 'Statewide'
        long_id += "-#{jurisdiction}"
      end

      long_id = long_id.gsub(' ', '_').gsub(',','_').gsub('.','')

      pp long_id

      description_fields = []    

      explanatory_statement = row.fetch('explanatory statement', nil)
      fiscal_impact = row.fetch('fiscal impact', nil)

      if explanatory_statement || fiscal_impact
        group = {
          :group => "Provided by state of WA",
          :items => []
        }
        state_data = [ [explanatory_statement, 'Explanatory statement by Office of Attorney General'], \
                       [fiscal_impact, 'Fiscal Impact Statement by Office of Financial Management']]
        state_data.each do |field|
          if field[0]
            field[0] = parse(field[0])
            group[:items].push({:label => field[1], :html => field[0]})
          end
        end
        description_fields.push group
      end

      if additional_description = row.fetch('additional_description', nil)
        description_fields = [{:label => 'Additional information', :html => parse(additional_description)}] 
      end

      description = row['description'].encode!('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
      if maplight_hash.has_key? long_id
        description, more_description_fields = fetchAndParseMeasureFromMaplight maplight_hash[long_id]
        description_fields += more_description_fields        
        # NOTE: preferring Maplight's description over our own. 
      end

      if row.fetch('url', nil)
        description += " Read the <a href='#{row['url']}' target='_blank'>full text</a>."
      end

      category = row['category']
      if jurisdiction == 'Statewide'
        if category == 'Advisory Measure'
          cluster = 'Advisory votes'
        else
          cluster = 'Statewide measures'
        end

      else 
        cluster = jurisdiction
      end

      measure = {
        :account_id => account.id,
        :user_id => 1, #TODO: make configurable
        :long_id => long_id,
        :name => row['topic'],
        :category => category,
        :designator => row['designator'],
        :description => description,
        :published => true, #TODO: make configurable

        :cluster => cluster,
        :description_fields => description_fields.length > 0 ? JSON.dump(description_fields) : nil,

        :url1 => row.fetch('url', nil),

        :seo_title => row.fetch('seo_title', nil),
        :seo_description => row.fetch('seo_description', nil),
        :seo_keywords => row.fetch('seo_keywords', nil)
      }

      proposal = Proposal.find_by_long_id long_id
      if !proposal
        proposal = Proposal.new measure
        proposal.save
        #pp "Added #{row['topic']}: #{long_id}"
      else
        measure.delete :account_id
        proposal.update_attributes measure
        pp "Updated #{row['topic']}"        
      end

    end

  end


  task :add_zips_for_proposals => :environment do 
    account = Account.find_by_identifier('livingvotersguide')

    jurisdiction_to_proposals = {}

    proposals = account.proposals.where('cluster is not null')
    proposals.each do |p|
      jurisdiction_to_proposals[p.cluster] = [] if !(jurisdiction_to_proposals.has_key?(p.cluster))
      jurisdiction_to_proposals[p.cluster].append p
    end

    jurisdiction_to_zips = {}
    CSV.foreach("lib/tasks/lvg/#{year}/jurisdictions.csv", :headers => true) do |row|
      jurisdiction = row['jurisdiction'].split.map(&:capitalize).join(' ')
      if !jurisdiction_to_zips.has_key?(jurisdiction)
        jurisdiction_to_zips[jurisdiction] = []
      end
      jurisdiction_to_zips[jurisdiction].push row['zip'].to_i
    end

    jurisdiction_to_proposals.each do |jurisdiction, proposals|
      jurisdiction = jurisdiction.split.map(&:capitalize).join(' ')
      zips = jurisdiction_to_zips[jurisdiction]
      if !jurisdiction_to_zips.has_key?(jurisdiction)
        pp "ERROR: jurisdiction #{jurisdiction} not found!...skipping"
        next
      end
      #pp "For #{jurisdiction}, adding #{zips.length} zips to #{proposals.length} measures"

      proposals.each do |p|
        p.hide_on_homepage = true
        p.zips = JSON.dump zips
        #pp p.zips
        p.save
      end

    end

  end  
end

