# use this elsewhere with: 
#   sheet = Services::GoogleSheet.new


# config taken from https://developers.google.com/sheets/api/quickstart/ruby
require 'google/apis/sheets_v4'
require "googleauth"
require "googleauth/stores/file_token_store"
require "fileutils"

OOB_URI = "urn:ietf:wg:oauth:2.0:oob".freeze
APPLICATION_NAME = "Consider.it".freeze
CLIENT_SECRETS_PATH = 'google.json' # This derives from a Google Service Account
CREDENTIALS_PATH = File.join(Dir.home, '.credentials',
                             "sheets.googleapis.yaml")
# The file token.yaml stores the user's access and refresh tokens, and is
# created automatically when the authorization flow completes for the first
# time.
TOKEN_PATH = "token.yaml".freeze
SCOPE = Google::Apis::SheetsV4::AUTH_SPREADSHEETS_READONLY

module Services
  class GoogleSheet
    ##
    # Ensure valid credentials, either by restoring from the saved credentials
    # files or intitiating an OAuth2 authorization. If authorization is required,
    # the user's default browser will be launched to approve the request.
    #
    # @return [Google::Auth::UserRefreshCredentials] OAuth2 credentials


    def authorize
      FileUtils.mkdir_p(File.dirname(CREDENTIALS_PATH))

      begin 
        client_id = Google::Auth::ClientId.from_file CLIENT_SECRETS_PATH
        token_store = Google::Auth::Stores::FileTokenStore.new file: CREDENTIALS_PATH
        authorizer = Google::Auth::UserAuthorizer.new client_id, SCOPE, token_store
        user_id = "default"
        credentials = authorizer.get_credentials user_id
        if credentials.nil?
          url = authorizer.get_authorization_url base_url: OOB_URI
          puts "Open the following URL in the browser and enter the " \
               "resulting code after authorization:\n" + url
          code = gets
          credentials = authorizer.get_and_store_credentials_from_code(
            user_id: user_id, code: code, base_url: OOB_URI
          )
        end
      rescue 
        credentials = Google::Auth::ServiceAccountCredentials.make_creds(
          scope: Google::Apis::SheetsV4::AUTH_SPREADSHEETS_READONLY,
          json_key_io: File.open(CLIENT_SECRETS_PATH))      
        credentials.fetch_access_token!
      end

      credentials
    end

    def getSheets(spreadsheet_id)
      pp "Getting Google Sheet #{spreadsheet_id}"
      service = Google::Apis::SheetsV4::SheetsService.new
      service.client_options.application_name = APPLICATION_NAME
      service.authorization = authorize

      sheets = []
      whole_sheet = service.get_spreadsheet spreadsheet_id
      whole_sheet.sheets.each do |sheet|
        sheets.append sheet.properties.title
      end

      sheets

    end 

    def getData(spreadsheet_id, range)
      pp "Getting data #{range} for Google Sheet #{spreadsheet_id}"
      service = Google::Apis::SheetsV4::SheetsService.new
      service.client_options.application_name = APPLICATION_NAME
      service.authorization = authorize

      service.get_spreadsheet_values spreadsheet_id, range
    end

  end
end