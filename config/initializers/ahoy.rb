
class Ahoy::Store < Ahoy::DatabaseStore

  # Save subdomain with visit
  def track_visit(data)
    if (subdomain = ActsAsTenant.current_tenant)
      data[:subdomain_id] = subdomain.id
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

# Ahoy's API controllers skip ApplicationController's callbacks, so the thread-local
# current_user and current_subdomain still hold whatever the last request on this
# thread set. Look both up from this request instead.
Ahoy.preserve_callbacks += [:get_current_subdomain] # sets the tenant from the request's host
Ahoy.protect_from_forgery = false # ahoy.js sends no CSRF token, so the session would be blanked
Ahoy.user_method = lambda do |controller|
  id = controller.session[:current_user_id]
  id && User.find_by(id: id)
end

# Ignore requests by Prerender
Ahoy.exclude_method = lambda do |controller, request|
  request.user_agent.index('Prerender') != nil || request.user_agent.index('HeadlessChrome') != nil
end

# For GDPR compliance
Ahoy.mask_ips = true

Ahoy.cookies = :none

# client side only
Ahoy.server_side_visits = :when_needed
Ahoy.api = true

# set to true for geocoding (and add the geocoder gem to your Gemfile)
# we recommend configuring local geocoding as well
# see https://github.com/ankane/ahoy#geocoding
Ahoy.geocode = false




