OpenAI.configure do |config|
    config.access_token = APP_CONFIG[:openai][:access]
    # config.organization_id = ENV.fetch('OPENAI_ORGANIZATION_ID') # Optional.
end
