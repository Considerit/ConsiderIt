if APP_CONFIG.has_key?(:mailgun_api_key) && Mailgun
  Mailgun.configure do |config|
    config.api_key = APP_CONFIG[:mailgun_api_key]
  end
end