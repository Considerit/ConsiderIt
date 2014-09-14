require 'csv'
require 'pp'

year = "2014"

# constructs a long_id from a data row
def create_long_id(proposal_data)
  long_id = proposal_data['topic'].gsub(' ', '_')
  if proposal_data['category'] && proposal_data['designator']
    long_id = "#{proposal_data['category'][0]}-#{proposal_data['designator']}_#{long_id}"
  end
  pp long_id
end

# maps from considerit long_ids to maplight measure/candidate ids
maplight_hash = {
  'I-522_Require_labels_on_GMO_foods' => '117',
  'I-517_Modify_initiative_processes' => '116'
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

  [ data['funding']['support'], data['funding']['oppose'] ].each_with_index do |funders, idx|
    endorser_type = "Donations in #{idx == 0 ? 'Support' : 'Opposition'} <span class='total_money_raised'>#{number_to_currency(funders['grand_total'], :precision => 0)}</span>"
    funding_html += "<div class='endorser_group funders #{idx == 0 ? 'support' : 'oppose'}'><div>#{endorser_type}</div><ul>"
    if funders['items'].length > 0
      for funder in funders['items'][0..10]
        funding_html += "<li><span class='funder_name'>#{funder['name'].split.map(&:capitalize).join(' ').gsub('Llc', 'LLC')}</span><span class='funder_amount'>#{number_to_currency(funder['amount'], :precision => 0)}</span></li>"
      end
      if funders['items'].length > 10
        funding_html += "<li class='other_donors'>...#{funders['items'].length - 10} other donors</li>"
      end
    else
      funding_html += "<li style='font-style: italic'>No funders yet</li>"
    end
    funding_html += "</ul></div>"
  end

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

  news_html += "<ul class='news'>"
  stories = data['news']
  stories.delete 'source'
  if data['news'].values().length > 0
    for story in data['news'].values()
      news_html += "<li><a href='#{story['url']}' rel='nofollow' target='_blank' style='text-decoration:underline'>#{story['headline']}</a><br>#{story['outlet']}, #{story['date']}</li>"
    end
  else
    news_html += "<li style='font-style: italic'>No news items yet</li>"
  end
  news_html += "</ul>"


  description_fields = [
    {
      :group => "Who supports each side?",
      :items => [{:label => 'Funding and endorsements', :html => "<div>#{funding_html}</div><div>#{endorsement_html}</div>"}, {:label => 'Editorials', :html => editorial_html}]
    },
    {
      :group => "Media coverage",
      :items => [{:label => 'News stories and debates', :html => news_html}]
    }
  ]

  return [data['summary']['main_summary'], description_fields]

end

namespace :lvg do

  task :import_proposals => :environment do
    account = Account.find_by_identifier('livingvotersguide')

    domains = {}
    measures = []

    CSV.foreach("lib/tasks/lvg/#{year}/measures.csv", :headers => true) do |row|
      long_id = create_long_id row

      description_fields = []    

      explanatory_statement = row.fetch('explanatory statement', nil)
      fiscal_impact = row.fetch('fiscal impact', nil)

      if explanatory_statement || fiscal_impact
        group = {
          :group => "Provided by state of WA",
          :items => []
        }
        state_data = [ [explanatory_statement, 'Explanatory statement by by Office of Attorney General'], \
                       [fiscal_impact, 'Fiscal Impact Statement by Office of Financial Management']]
        state_data.each do |field|
          if field[0]
            field[0] = field[0].encode!('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
            group[:items].push({:label => field[1], :html => field[0]})
          end
        end
        description_fields.push group
      end

      if additional_description = row.fetch('additional_description', nil)
        description_fields = [{:label => 'Additional information', :html => additional_description.encode!('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')}] 
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

      description_fields = nil if description_fields == [] 

      jurisdiction = row['jurisdiction'].split.map(&:capitalize).join(' ')

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
        :description_fields => JSON.dump(description_fields),

        :url1 => row.fetch('url', nil),

        :seo_title => row.fetch('seo_title', nil),
        :seo_description => row.fetch('seo_description', nil),
        :seo_keywords => row.fetch('seo_keywords', nil)
      }

      proposal = Proposal.find_by_long_id long_id
      if !proposal
        proposal = Proposal.new measure
        proposal.save

        pp "Added #{row['topic']}"
      else
        measure.delete :account_id
        proposal.update_attributes measure
        pp "Updated #{row['topic']}"        
      end

    end

  end


  task :add_zips_for_proposals => :environment do 

    jurisdiction_to_proposals = {}

    CSV.foreach("lib/tasks/lvg/#{year}/measures.csv", :headers => true) do |row|
      proposal = Proposal.find_by_long_id(create_long_id(row))
      if !proposal
        throw 'Could not find proposal'
      end
      # jurisdiction = row['jurisdiction'].split.map(&:capitalize).join(' ')

      # proposal.cluster = jurisdiction
      proposal.save

      # if jurisdiction == 'Statewide'
      #   proposal.add_tag 'type:statewide'
      #   proposal.add_tag "jurisdiction:State of Washington"
      #   proposal.add_seo_keyword 'Statewide'
      #   proposal.save
      #   next
      # end

      if jurisdiction != 'Statewide' #everyone has access to these...
        if !(jurisdiction_to_proposals.has_key?(jurisdiction))
          jurisdiction_to_proposals[jurisdiction] = []
        end
        jurisdiction_to_proposals[jurisdiction].push proposal
      end
    end

    jurisdiction_to_zips = {}
    CSV.foreach("lib/tasks/lvg/#{year}/jurisdictions.csv", :headers => true) do |row|
      jurisdiction = row['jurisdiction'].split.map(&:capitalize).join(' ')
      if !jurisdiction_to_zips.has_key?(jurisdiction)
        jurisdiction_to_zips[jurisdiction] = []
      end
      jurisdiction_to_zips[jurisdiction].push row['zip']
    end

    jurisdiction_to_proposals.each do |jurisdiction, proposals|
      jurisdiction = jurisdiction.split.map(&:capitalize).join(' ')
      zips = jurisdiction_to_zips[jurisdiction]
      if !jurisdiction_to_zips.has_key?(jurisdiction)
        pp "ERROR: jurisdiction #{jurisdiction} not found!...skipping"
        next
      end
      pp "For #{jurisdiction}, adding #{zips.length} zips to #{proposals.length} measures"

      # proposals.each do |p|
      #   p.add_tag "type:local"
      #   p.add_tag "jurisdiction:#{jurisdiction}"
      #   p.add_seo_keyword jurisdiction

      #   zips.each do |zip|
      #     p.targettable = true
      #     p.add_tag "zip:#{zip}"
      #   end
      #   p.save

      # end

    end

  end  
end

