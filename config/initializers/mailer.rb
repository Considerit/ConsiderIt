Mailhopper::Base.setup do |config|
  config.default_delivery_method = :smtp

  # TODO: remove this once Mailhopper is updated to work with Rails 3.2
  class Mailhopper::Queue 
    def settings 
      {:return_response => false}
    end
  end
end

Premailer::Rails.config.merge!(
  :preserve_styles => false,
  :remove_ids      => true,
  :remove_classes => true)