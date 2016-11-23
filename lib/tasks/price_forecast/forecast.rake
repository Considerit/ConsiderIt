# See Google API docs at: 
#   - https://developers.google.com/sheets/quickstart/ruby
#   - https://developers.google.com/sheets/guides/batchupdate


# tiers are pricing tiers: 
#    [ {from: 0, to:10, per: 0}, {from: 10, to: 100, per: 10}, ...]
# stats are the subdomain metrics for the month
def stakeholders(stats, base, tiers)
  engaged = stats[:unique_engaged]
  tier_idx = 0
  cost = 0

  while engaged > 0
    tier = tiers[tier_idx]
    at_this_tier = [engaged, tier[:range][1] - tier[:range][0]].min
    cost += tier[:per] * at_this_tier
    engaged -= at_this_tier
    tier_idx += 1
  end

  base + cost
end


def opinions(stats, base, tiers)
  engaged = stats[:opinions]
  tier_idx = 0
  cost = 0

  while engaged > 0
    tier = tiers[tier_idx]
    at_this_tier = [engaged, tier[:range][1] - tier[:range][0]].min
    cost += tier[:per] * at_this_tier
    engaged -= at_this_tier
    tier_idx += 1
  end

  base + cost
end



plans = {}
plans['engaged_stakeholder_base10'] =     lambda { |stats| stakeholders(stats, 150, [ {range: [0, 10], per: 0}, {range: [10, 100], per: 10}, {range: [100, 1000], per: 7}, {range: [1000, 10000], per: 5}, {range: [10000,Float::INFINITY], per: 3}])}
plans['engaged_stakeholder_no_base']  =   lambda { |stats| stakeholders(stats,   0, [ {range: [0, 10], per: 0}, {range: [10, 100], per: 10}, {range: [100, 1000], per: 7}, {range: [1000, 10000], per: 5}, {range: [10000,Float::INFINITY], per: 3}])}
plans['engaged_stakeholder_expensive']  = lambda { |stats| stakeholders(stats, 100, [ {range: [0, 100], per: 10}, {range: [100, 1000], per: 8.5}, {range: [1000, 10000], per: 6.50}, {range: [10000,Float::INFINITY], per: 5}])}

plans['opinions_base10'] =                lambda { |stats| opinions(stats, 100, [ {range: [0, 100], per: 0}, {range: [100, 1000], per: 3}, {range: [1000, 10000], per: 2}, {range: [10000, 100000], per: 1}, {range: [100000,Float::INFINITY], per: 0.5}])}
plans['opinions_base10_mock'] =           lambda { |stats| opinions(stats, 100, [ {range: [0, 100], per: 0}, {range: [100, 1000], per: 2.5}, {range: [1000, 10000], per: 1.75}, {range: [10000, 100000], per: 1}, {range: [100000,Float::INFINITY], per: 0.65}])}

plans['opinions_dropoff'] =               lambda { |stats| opinions(stats, 100, [ {range: [0, 100], per: 0}, {range: [100, 500], per: 3}, {range: [500, 1000], per: 2}, {range: [1000, 2000], per: 1}, {range: [1600,Float::INFINITY], per: 0.75}])}
plans['opinions_short'] =                 lambda { |stats| opinions(stats, 100, [ {range: [0, 250], per: 1.75}, {range: [250, 1000], per: 1.4}, {range: [1000, 2000], per: 1}, {range: [2000,Float::INFINITY], per: 0.75}])}
plans['opinions_short_zero'] =            lambda { |stats| opinions(stats,  0, [ {range: [0, 250], per: 1.75}, {range: [250, 1000], per: 1.4}, {range: [1000, 2000], per: 1}, {range: [2000,Float::INFINITY], per: 0.6}])}


task :pricing_forecasts => :environment do

  now = DateTime.now

  revenue = {}

  earliest_month = 0
  month_cutoff = 12
  Subdomain.all.each do |subdomain|
    # next unless ['bitcoin', 'wsffn'].include?(subdomain.name.downcase)

    ignore_subs = ["bradywalkinshaw", "cali", "us", "consider", "allsides", "livingvotersguide", "swotconsultants", "galacticfederation", "MSNBC","washingtonpost","MsTimberlake","design","Relief-Demo","sosh","GS-Demo","impacthub-demo","librofm","bitcoin-demo","amberoon","SocialSecurityWorks","Airbdsm","event","lyftoff","Schools","ANUP2015","CARCD-demo","news","Committee-Meeting","Cattaca","AMA-RFS","economist","ITFeedback","kevin","program-committee-demo","ECAST-Demo"]

    next if subdomain.proposals.count < 10 || ignore_subs.include?(subdomain.name)

    contributed_in = {}
    opinions = {}
    contribution_tables = [Proposal, Comment, Point, Opinion]
    contribution_tables.each do |table|
      if table == Opinion 
        qry = table.select(:created_at, :user_id, :point_inclusions)
      else 
        qry = table.select(:created_at, :user_id)
      end
      if [Point,Opinion,Proposal].include? table 
        qry = qry.where(:published => true)
      end 

      qry = qry.where :subdomain_id => subdomain.id

      qry.each do |item|
        days_since = (now - item.created_at.to_datetime).to_i
        months_ago = (days_since / 30).to_i

        next if months_ago > month_cutoff

        if table == Opinion 
          if !opinions.has_key?(months_ago)
            opinions[months_ago] = 0
          end 
          opinions[months_ago] += 1
        end

        if !contributed_in.has_key?(months_ago)
          contributed_in[months_ago] = {}
        end
        if !contributed_in[months_ago].has_key?(item.user_id)
          contributed_in[months_ago][item.user_id] = 0
        end 
        contributed_in[months_ago][item.user_id] += 1

        if table == Opinion 
          inc = JSON.parse((item.point_inclusions || '[]'))
          contributed_in[months_ago][item.user_id] += inc.length
        end 
      end

    end

    
    contributed_in.each do |months_ago, users|
      if months_ago > earliest_month
        earliest_month = months_ago
      end

      stats = {
        :unique_engaged => users.keys().length,
        :opinions => opinions[months_ago] || 0 
      }

      plans.each do |plan, calc| 
        if !revenue.has_key?(plan)
          revenue[plan] = {}
        end
        if !revenue[plan].has_key?(subdomain.name)
          revenue[plan][subdomain.name] = {}
        end 

        revenue[plan][subdomain.name][months_ago] = calc.call stats
      end 
    end 

  end

  push_to_spreadsheet revenue, [earliest_month, 23].min
end

def push_to_spreadsheet(revenue, earliest_month)
  spreadsheet_id = '1WdqgiTTNiyHbPmxvPFjwwRyPGw8f0LfaOWQP3D5_oR8'
  
  # Initialize the API
  service = Google::Apis::SheetsV4::SheetsService.new
  service.client_options.application_name = APPLICATION_NAME
  service.authorization = authorize

  spreadsheet = service.get_spreadsheet spreadsheet_id

  sheets = {}
  spreadsheet.sheets.each do |sheet|
    sheets[sheet.properties.title] = sheet.properties.sheet_id
  end


  revenue.each do |plan, fora|
    requests = []
    if !sheets.has_key?(plan)
      requests.push( {
        add_sheet: {
          properties: {
            title: plan
          }
        }
      })
      response = service.batch_update_spreadsheet(spreadsheet_id, {requests: requests}, {})
      requests = []
    end 

    sheet_id = sheets[plan]

    rows = []
    header = [{user_entered_value: {:string_value=> "Forum"}}]
    (0..earliest_month).each do |m|
      m = earliest_month - m
      header.push({user_entered_value: {:string_value=> "#{m} months ago"}})
    end
    rows.push({values: header})

    fora.each do |forum, moola| 
      row = []
      row.push({user_entered_value: {:string_value=> forum}})

      (0..earliest_month).each do |m|
        m = earliest_month - m 
        if !moola.has_key?(m)
          moola[m] = 0
        end 
        row.push({user_entered_value: {:number_value=> moola[m]}})
      end 
      rows.push({values: row})
    end

    requests.push({
      update_cells: {
        start: {sheet_id: sheet_id, row_index: 0, column_index: 0},
        rows: rows,
        fields: 'userEnteredValue'
      }
    })


    requests.push({
      update_cells: {
        start: {sheet_id: sheet_id, row_index: fora.keys.length + 1, column_index: 0},
        rows: [{values: [{user_entered_value: {:string_value=>'Total this month'}}]}],
        fields: 'userEnteredValue'
      }
    })

    requests.push({
      update_cells: {
        start: {sheet_id: sheet_id, row_index: 0, column_index: earliest_month + 2},
        rows: [{values: [{user_entered_value: {:string_value=>'Total this customer'}}]}],
        fields: 'userEnteredValue'
      }
    })


    requests.push({
      repeat_cell: {
        range: {
          sheet_id: sheet_id,
          start_row_index: fora.keys.length + 1,
          end_row_index: fora.keys.length + 2,
          start_column_index: 1,
          end_column_index: earliest_month + 2
        },
        cell: {user_entered_value: {formula_value: "=sum(B2:B#{fora.keys.length + 1})"}},
        fields: 'userEnteredValue'
      }
    })

    requests.push({
      repeat_cell: {
        range: {
          sheet_id: sheet_id,
          start_row_index: 1,
          end_row_index: fora.keys.length + 2,
          start_column_index: earliest_month + 2,
          end_column_index: earliest_month + 3
        },
        cell: {user_entered_value: {formula_value: "=sum(B2:#{(65 + earliest_month + 1).chr}2)"}},
        fields: 'userEnteredValue'
      }
    })


    response = service.batch_update_spreadsheet(spreadsheet_id, {requests: requests}, {})

  end 


end


require 'google/apis/sheets_v4'
require 'googleauth'
require 'googleauth/stores/file_token_store'

require 'fileutils'

OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'
APPLICATION_NAME = 'Google Sheets API Ruby Quickstart'
CLIENT_SECRETS_PATH = 'client_secret.json'
CREDENTIALS_PATH = File.join(Dir.home, '.credentials',
                             "sheets.googleapis.com-ruby-quickstart.yaml")
SCOPE = Google::Apis::SheetsV4::AUTH_SPREADSHEETS

##
# Ensure valid credentials, either by restoring from the saved credentials
# files or intitiating an OAuth2 authorization. If authorization is required,
# the user's default browser will be launched to approve the request.
#
# @return [Google::Auth::UserRefreshCredentials] OAuth2 credentials
def authorize
  FileUtils.mkdir_p(File.dirname(CREDENTIALS_PATH))

  client_id = Google::Auth::ClientId.from_file(CLIENT_SECRETS_PATH)
  token_store = Google::Auth::Stores::FileTokenStore.new(file: CREDENTIALS_PATH)
  authorizer = Google::Auth::UserAuthorizer.new(
    client_id, SCOPE, token_store)
  user_id = 'default'
  credentials = authorizer.get_credentials(user_id)
  if credentials.nil?
    url = authorizer.get_authorization_url(
      base_url: OOB_URI)
    puts "Open the following URL in the browser and enter the " +
         "resulting code after authorization"
    puts url
    code = gets
    credentials = authorizer.get_and_store_credentials_from_code(
      user_id: user_id, code: code, base_url: OOB_URI)
  end
  credentials
end
