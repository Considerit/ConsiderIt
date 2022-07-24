
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
    permitted = permit('create subdomain')
    if permitted < 0
      if params[:sso_domain]
        # redirect to IdP for authentication
        initiate_saml_auth(params[:sso_domain])
        return
      else 
        raise PermissionDenied.new permitted
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
      end 

      new_subdomain.save

      set_current_tenant new_subdomain

      if !params[:skip_seeding]

        # create a sample list
        # customizations = {
        #   "list/initial": {
        #     "list_title": "How do you want Consider.it to help you?",
        #     "list_description": "Experiment with the proposals in this list however you want. When you’re done, you can delete the entire proposal list via the gear icon in the upper right.",
        #     "list_category": "",
        #     "list_opinions_title": "",
        #     "slider_pole_labels": {
        #       "support": 'Important to me',
        #       "oppose": 'Unimportant'
        #     },
        #     "show_proposer_icon": false
        #   }
        # }

        customizations = {
          "list/initial": {
            "list_title": "What are your favorite ice cream flavors?",
            "list_description": "Experiment with the proposed flavors however you want. When you’re done, you can delete the entire proposal list via the gear icon in the upper right.",
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

         # Seed new proposals in sample list       
        # proposals = ['Collect feedback from many stakeholders', 
        #              'Help me make decisions with peers', 
        #              'Talk with peers about things we care about', 
        #              'Help people get on the same page', 
        #              'Something else']

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
            proposal.pic = open(img)
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
      raise PermissionDenied.new Permission::DISABLED
    end

    update_roles    

    fields = ['roles', 'customizations', 'lang', 'moderation_policy', 'about_page_url', 'external_project_url', 'google_analytics_code']
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

    current_user.add_to_active_in
    current_subdomain.update_attributes! attrs

    response = current_subdomain.as_json
    if errors.length > 0
      response[:errors] = errors
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
    current_subdomain.proposals.destroy_all
    current_subdomain.opinions.destroy_all
    current_subdomain.points.destroy_all
    current_subdomain.comments.destroy_all

    dirty_key '/subdomain'
    dirty_key '/proposals'

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

    current_subdomain.update_attributes attrs
    dirty_key '/subdomain'
    render :json => []
  end

end

