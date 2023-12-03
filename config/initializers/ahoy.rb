
class Ahoy::Store < Ahoy::DatabaseStore

  # Save subdomain with visit
  def track_visit(data)
    if current_subdomain
      data[:subdomain_id] = current_subdomain.id
      @visit = visit_model.create!(slice_data(visit_model, data))
    end
  rescue => e
    raise e unless unique_exception?(e)

    # so next call to visit will try to fetch from DB
    if defined?(@visit)
      remove_instance_variable(:@visit)
    end
  end

end

# Ignore requests by Prerender
Ahoy.exclude_method = lambda do |controller, request|
  request.user_agent.index('Prerender') != nil || request.user_agent.index('HeadlessChrome') != nil
end

# For GDPR compliance
Ahoy.mask_ips = true
Ahoy.cookies = false

# Ahoy.cookies = :none  # comment this in when upgrading to Ahoy 5

# client side only
Ahoy.server_side_visits = :when_needed
Ahoy.api = true

# set to true for geocoding (and add the geocoder gem to your Gemfile)
# we recommend configuring local geocoding as well
# see https://github.com/ankane/ahoy#geocoding
Ahoy.geocode = false




