
has_aws = Rails.env.production? && APP_CONFIG.has_key?(:aws) && APP_CONFIG[:aws].has_key?(:access_key_id) && !APP_CONFIG[:aws][:access_key_id].nil?

if has_aws
  ActionMailer::Base.add_delivery_method :ses, AWS::SES::Base,
    :access_key_id     => APP_CONFIG[:aws][:access_key_id],
    :secret_access_key => APP_CONFIG[:aws][:secret_access_key]
end

Mailhopper::Base.setup do |config|

  config.default_delivery_method = has_aws ? :ses : :smtp

  # TODO: remove this once Mailhopper is updated to work with Rails 3.2
  class Mailhopper::Queue 
    def settings 
      {:return_response => false}
    end
  end
end

