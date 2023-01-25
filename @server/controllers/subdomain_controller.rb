
# for Plausible API calls
require 'uri'
require 'net/http'

class SubdomainController < ApplicationController
  skip_before_action :verify_authenticity_token, :only => :update_images_hack
  include Invitations

  before_action :verify_user, only: [:create]

  def index 
    ActsAsTenant.without_tenant do 
      subdomains = Subdomain.where('name != "homepage"').map {|s| {:id => s.id, :name => s.name, :customizations => s.customizations, :activity => s.points.published.count} }
      render :json => [{
        key: '/subdomains',
        subs: subdomains
      }]
    end
  end

  def create
    permitted = Permissions.permit('create subdomain')
    if permitted < 0
      if params[:sso_domain]
        # redirect to IdP for authentication
        initiate_saml_auth(params[:sso_domain])
        return
      else 
        raise Permissions::Denied.new permitted
      end
    end

    errors = []

    # force it to come from consider.it
    if current_subdomain.name != 'homepage'
      errors.push "You can only create new forums from https://#{APP_CONFIG[:domain]}"
    end

    # make sure this user hasn't been spam-creating subdomains...
    if !current_user.super_admin
      subs_for_user = Subdomain.where("roles like '%\"/user/#{current_user.id}\"%'").where("created_at >= :week", {:week => 1.week.ago})
      if subs_for_user.count > 25
        errors.push "You have created too many forums in the past week."
      end
    end 

    # TODO: sanitize / make sure has url-able characters
    subdomain = params[:subdomain]
    subdomain = subdomain.downcase.strip.gsub(' ', '-').gsub(/[^\w-]/, '')

    if !subdomain
      errors.push "You must specify a forum name"
    end 

    existing = Subdomain.find_by_name(subdomain) || ['aeb', 'cs', 'de', 'en', 'es', 'fr', 'heb', 'hu', 'mi', 'nl', 'pt', 'sk'].index(subdomain) || subdomain.start_with?('oauth-')
    if existing
      errors.push "That forum already exists. Please choose a different name."
    end 

    if errors.length > 0
      if request.request_method == 'POST' && !request.xhr?
        redirect_to "/create_forum?error=#{errors[0]}"
      else 
        render :json => [{errors: errors}]
      end
    else      
      new_subdomain = Subdomain.new name: subdomain
      roles = new_subdomain.user_roles
      roles['admin'].push "/user/#{current_user.id}"
      roles['visitor'].push "*"
      new_subdomain.roles = roles
      new_subdomain.created_by = current_user.id

      if params[:sso_domain]
        new_subdomain.SSO_domain = params[:sso_domain]
      end

      if (params[:upgrade] && current_user.paid_forums > Subdomain.where(:created_by => current_user).where("plan > 0").count) || (Rails.env == 'development' && params[:skip_seeding])
        new_subdomain.plan = 1
        create_plausible_domain new_subdomain
      end 

      new_subdomain.save

      set_current_tenant new_subdomain

      if !params[:skip_seeding]


        if params[:copy_from] && params[:copy_from].length > 0 
          template_sub = Subdomain.find(params[:copy_from].to_i)

          # validate that current user is a host of template_sub
          if Permissions.permit 'update subdomain', template_sub
            new_subdomain.import_configuration template_sub
          end

        else 
          customizations = {
            "list/initial": {
              "list_title": "What are your favorite ice cream flavors?",
              "list_description": "Experiment with the proposed flavors however you want. When you’re done, you can delete this entire Ice Cream silliness via the three-dots icon in the upper right.",
              "list_item_name": "flavor",
              "list_opinions_title": "",
              "slider_pole_labels": {
                "support": 'Yummy',
                "oppose": 'Yucky'
              }
            }
          }

          new_subdomain.customizations = customizations
          new_subdomain.save

          proposals = [
            {name: 'Vanilla', img: "https://f.consider.it/icecreams/vanilla.jpeg" },
            {name: 'Chocolate', img: "https://f.consider.it/icecreams/chocolate.jpeg" },
            {name: 'Cookies in Cream', img: "https://f.consider.it/icecreams/cookies-n-cream.jpeg" },
            {name: 'Mint chocolate chip', img: "https://f.consider.it/icecreams/mint-chocolate-chip.jpeg" },
            {name: 'Salted caramel', img: "https://f.consider.it/icecreams/salted-caramel.jpeg" },
            {name: 'Eggnog', img: "https://f.consider.it/icecreams/eggnog.jpeg" }
          ]


          proposals.each do |p|
            proposal_name = p[:name]
            img = p[:img]

            proposal = Proposal.new({
              subdomain_id: new_subdomain.id, 
              slug: proposal_name.gsub(' ', '-').downcase,
              name: proposal_name,
              description: '',
              user: current_user,
              cluster: 'initial',
              active: true,
              published: true, 
              moderation_status: 1,
              roles: {
                "editor": ["/user/#{current_user.id}"]
              }
            })
            if img 
              proposal.pic = URI.open(img)
            end
            proposal.save

            opinion = Opinion.create!({
              published: true,         
              user: current_user,
              subdomain_id: new_subdomain.id, 
              proposal: proposal,
              stance: 0.0
            })
          end 
        end

      end
      
      current_user.add_to_active_in new_subdomain

      set_current_tenant(Subdomain.find_by_name('homepage'))

      # Send welcome email to subdomain creator
      UserMailer.welcome_new_customer(current_user, new_subdomain).deliver_later

      if request.xhr?
        render :json => [{key: 'new_subdomain', name: new_subdomain.name, t: current_user.auth_token(new_subdomain)}]
      else 
        token = current_user.auth_token(new_subdomain)
        if Rails.env.development?
          redirect_to "/?u=#{current_user.email}&t=#{token}&domain=#{new_subdomain.name}"
        else
          redirect_to "#{request.protocol}#{new_subdomain.url}?u=#{current_user.email}&t=#{token}"
        end
      end
    end
  end



  def show
    if params[:id]
      dirty_key "/subdomain/#{params[:id] or current_subdomain.id}"
    elsif params[:subdomain]
      begin 
        subdomain = Subdomain.find_by_name(params[:subdomain])
        dirty_key "/subdomain/#{subdomain.id}"
      rescue 
        render :json => [{errors: ["That site doesn't exist."]}]
        return
      end
    else 
      dirty_key '/subdomain'
    end
    render :json => []
  end

  def update
    errors = []

    subdomain = Subdomain.find(params[:id])
    authorize! 'update subdomain', subdomain

    if subdomain.id != current_subdomain.id
      raise Permissions::Denied.new Permissions::Status::DISABLED
    end

    update_roles    

    fields = ['roles', 'customizations', 'lang', 'moderation_policy', 'about_page_url', 'external_project_url']
    attrs = params.select{|k,v| fields.include? k}.to_h

    if current_user.super_admin && params.has_key?('plan')
      attrs['plan'] = params['plan'].to_i
    end 

    sanitize_fields = ['lang', 'about_page_url', 'external_project_url', 'google_analytics_code']
    sanitize_fields.each do |field| 
      if attrs.has_key?(field)
        attrs[field] = sanitize_helper(attrs[field])
      end      
    end

    sanitize_json = ['roles', 'customizations']
    sanitize_json.each do |field| 
      if attrs.has_key?(field)
        attrs[field] = sanitize_json(attrs[field], subdomain[field])
      end      
    end


    if params[:copy_from]
      template_sub = Subdomain.find(params[:copy_from].to_i)

      # validate that current user is a host of template_sub
      if Permissions.permit 'update subdomain', template_sub
        subdomain.import_configuration template_sub
      end
    end

    change_in_plausible_status = attrs['customizations'] && attrs['customizations']['enable_plausible_analytics'] != current_subdomain.customizations['enable_plausible_analytics']


    current_user.add_to_active_in
    current_subdomain.update! attrs

    response = current_subdomain.as_json
    if errors.length > 0
      response[:errors] = errors
    elsif change_in_plausible_status
      if current_subdomain.customizations['enable_plausible_analytics']
        create_plausible_domain
      else 
        destroy_plausible_domain
      end
    end
    render :json => [response]

  end

  def update_roles
    if params.has_key?('roles')
      roles = params['roles']

      if params.has_key?('invitations') && params['invitations']
        roles = process_and_send_invitations(roles, params['invitations'], current_subdomain)
      end
      # rails replaces [] with nil in params for some reason...
      roles.each do |k,v|
        roles[k] = [] if !v
      end

      dirty_key '/proposals' # proposals inherit roles from subdomain

      current_subdomain.roles = roles
    end
  end

  def nuke_everything
    if Permissions.permit 'update subdomain', current_subdomain
      current_subdomain.proposals.destroy_all
      current_subdomain.opinions.destroy_all
      current_subdomain.points.destroy_all
      current_subdomain.comments.destroy_all

      dirty_key '/subdomain'
      dirty_key '/proposals'
    end

    render :json => []
  end

  def create_plausible_domain(subdomain=nil)
    pp "CREATING!"
    begin
      subdomain ||= current_subdomain

      site = "#{subdomain.name}.#{APP_CONFIG[:plausible_domain]}"
      # curl -X POST https://plausible.io/api/v1/sites \
      #   -H "Authorization: Bearer ${TOKEN}" \
      #   -F 'domain="test-domain.com"' \
      #   -F 'timezone="America/Los_Angeles"'

      uri = URI('https://plausible.io/api/v1/sites')
      req = Net::HTTP::Post.new(uri)
      req.set_form_data('domain' => site, 'timezone' => 'America/Los_Angeles')
      req['Authorization'] = "Bearer #{APP_CONFIG[:plausible_api_key]}"

      res = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => true) do |http|
        http.request(req)
      end

      # curl -X PUT https://plausible.io/api/v1/sites/goals \
      #   -H "Authorization: Bearer ${TOKEN}" \
      #   -F 'site_id="test-domain.com"' \
      #   -F 'goal_type="event"' \
      #   -F 'event_name="Signup"'

      uri = URI('https://plausible.io/api/v1/sites/goals')
      req = Net::HTTP::Put.new(uri)
      req.set_form_data('site_id' => site, 'goal_type' => "event", 'event_name' => 'Signup')
      req['Authorization'] = "Bearer #{APP_CONFIG[:plausible_api_key]}"

      res = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => true) do |http|
        http.request(req)
      end

    rescue => e
      ExceptionNotifier.notify_exception(e) 
      pp "Could not create plausible domain #{site}", e
    end


  end

  def destroy_plausible_domain(subdomain=nil)
    begin

      subdomain ||= current_subdomain

      site = "#{subdomain.name}.#{APP_CONFIG[:plausible_domain]}"

      # curl -X DELETE https://plausible.io/api/v1/sites/test-domain.com \
      #   -H "Authorization: Bearer ${TOKEN}"
      uri = URI("https://plausible.io/api/v1/sites/#{site}")
      req = Net::HTTP::Delete.new(uri)
      req['Authorization'] = "Bearer #{APP_CONFIG[:plausible_api_key]}"
      res = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => true) do |http|
        http.request(req)
      end
    rescue => e
      ExceptionNotifier.notify_exception(e) 
      pp "Could not destroy plausible domain"
    end
  end

  def destroy
    subdomain_id = params['subdomain_to_destroy']    
    sub_to_destroy = Subdomain.find(subdomain_id.to_i)
    if sub_to_destroy && Permissions.permit('update subdomain', sub_to_destroy)
      sub_to_destroy.destroy()
    end

    dirty_key '/your_forums'
    render :json => []
  end

  def copy_from 

    template_sub = Subdomain.find(params[:subdomain_to_import_configuration].to_i)

    # validate that current user is a host of template_sub
    if Permissions.permit('update subdomain', template_sub) && Permissions.permit('update subdomain', current_subdomain)
      current_subdomain.import_configuration template_sub
    end

    render :json => []

  end

  def rename_forum
    old_name = current_subdomain.name

    name = params[:name]
    name = name.downcase.strip.gsub(' ', '-').gsub(/[^\w-]/, '')

    begin 
      current_subdomain.rename(name)
    rescue
      return render :json => [:error => "That subdomain is not available"]
    end
    if request.url.index(old_name)
      redirect_to request.url.sub old_name, name
    end
  end

  def update_images_hack
    attrs = {}
    if masthead = params['masthead']
      if masthead == '*delete*'
        attrs['masthead'] = nil
        current_subdomain.customizations.fetch('banner', {}).delete('background_image_url')
        current_subdomain.save        
      else 
        attrs['masthead'] = masthead
      end 
    end
    if logo = params['logo']
      if logo == '*delete*'
        attrs['logo'] = nil
      else 
        attrs['logo'] = params['logo']
      end
    end

    current_subdomain.update! attrs
    dirty_key '/subdomain'
    render :json => []
  end

end

