module Invitations
end

class SubdomainController < ApplicationController
  skip_before_action :verify_authenticity_token, :only => :update_images_hack
  include Invitations

  before_action :verify_user, only: [:create]

  def index 
    ActsAsTenant.without_tenant do 
      subdomains = Subdomain.where('name != "homepage"').map {|s| {:id => s.id, :name => s.name, :customizations => s.customizations, :activity => s.proposals.count > 1 || s.opinions.published.count > 1 || s.points.published.count > 0}}
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
      errors.push 'You can only create subdomains from https://consider.it'
    end

    # make sure this user hasn't been spam-creating subdomains...
    if !current_user.super_admin
      subs_for_user = Subdomain.where("roles like '%\"/user/#{current_user.id}\"%'").where("created_at >= :week", {:week => 1.week.ago})
      if subs_for_user.count > 25
        errors.push "You have created too many subdomains in the past week."
      end
    end 

    # TODO: sanitize / make sure has url-able characters
    subdomain = params[:subdomain]
    subdomain = subdomain.downcase.strip.gsub(' ', '-').gsub(/[^\w-]/, '')

    if !subdomain
      errors.push "You must specify a subdomain name"
    end 

    existing = Subdomain.find_by_name(subdomain)
    if existing
      errors.push "That site already exists. Please choose a different name."
    end 

    if errors.length > 0
      if request.request_method == 'POST' && !request.xhr?
        redirect_to "/create_forum?error=#{errors[0]}"
      else 
        render :json => [{errors: errors}]
      end
    else      
      new_subdomain = Subdomain.new name: subdomain, app_title: params[:app_title]
      roles = new_subdomain.user_roles
      roles['admin'].push "/user/#{current_user.id}"
      roles['visitor'].push "*"
      new_subdomain.roles = JSON.dump roles

      new_subdomain.host = "#{new_subdomain.name}.#{request.host}"
      new_subdomain.host_with_port = "#{new_subdomain.name}.#{request.host_with_port}"

      if params[:sso_domain]
        new_subdomain.SSO_domain = params[:sso_domain]
      end
      new_subdomain.save

      set_current_tenant(new_subdomain)

      # Seed a new proposal
      proposal = Proposal.new({
        subdomain_id: new_subdomain.id, 
        slug: 'considerit_can_help', 
               # if you change the slug, be sure to update the 
               # welcome_new_customer email template
        name: 'Consider.it can help me',
        description: '',
        user: current_user,
        cluster: 'Test question',
        active: true,
        published: true, 
        moderation_status: 1,
        roles: "{\"editor\":[\"/user/#{current_user.id}\"],\"writer\":[\"*\"],\"commenter\":[\"*\"],\"opiner\":[\"*\"],\"observer\":[\"*\",\"*\"]}"
      })
      proposal.save

      opinion = Opinion.create!({
        published: true,         
        user: current_user,
        subdomain_id: new_subdomain.id, 
        proposal: proposal,
        stance: 0.0
      })
      current_user.add_to_active_in(new_subdomain)

      set_current_tenant(Subdomain.find_by_name('homepage'))

      # Send welcome email to subdomain creator
      UserMailer.welcome_new_customer(current_user, new_subdomain, params[:plan]).deliver_later

      if request.xhr?
        render :json => [{key: 'new_subdomain', name: new_subdomain.name, t: current_user.auth_token(new_subdomain)}]
      else 
        token = current_user.auth_token(new_subdomain)
        redirect_to "#{request.protocol}#{new_subdomain.host_with_port}?u=#{current_user.email}&t=#{token}"
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

    if subdomain.id != current_subdomain.id #&& !current_user.super_admin
      # for now, don't allow modifying non-current subdomain
      raise PermissionDenied.new Permission::DISABLED
    end

    fields = ['lang', 'moderate_points_mode', 'moderate_comments_mode', 'moderate_proposals_mode', 'about_page_url', 'notifications_sender_email', 'app_title', 'external_project_url', 'google_analytics_code']
    attrs = params.select{|k,v| fields.include? k}

    update_roles

    serialized_fields = ['roles', 'branding']
    for field in serialized_fields
      if params.has_key? field
        attrs[field] = JSON.dump params[field]
      end
    end

    if current_user.super_admin && params.has_key?('plan')
      attrs['plan'] = params['plan'].to_i
    end 

    if current_user.super_admin && params.has_key?('customizations')
      attrs['customizations'] = params['customizations']
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
      if params.has_key?('invitations') && params['invitations']
        params['roles'] = process_and_send_invitations(params['roles'], params['invitations'], current_subdomain)
      end
      # rails replaces [] with nil in params for some reason...
      params['roles'].each do |k,v|
        params['roles'][k] = [] if !v
      end
      current_subdomain.roles = JSON.dump params['roles']
    end
  end

  def update_images_hack
    attrs = {}
    if params['masthead']
      attrs['masthead'] = params['masthead']
    end
    if params['logo']
      attrs['logo'] = params['logo']
    end

    current_tenant.update_attributes attrs
    dirty_key '/subdomain'
    render :json => []
  end

end

module Invitations
  def process_and_send_invitations(roles, invitations, target)

    
    invitations.each do |invite|
      message = invite['message'] && invite['message'].length > 0 ? invite['message'] : nil
      users_with_role = roles[invite['role']]

      invites = invite['keys_or_emails']
      if !invites
        invites = []
      end

      invites.each do |user_or_email|
        next if user_or_email.index('*') # wildcards; no invitations!!
          
        if user_or_email[0] == '/'
          invitee = User.find(key_id(user_or_email))

        else 
          # check to make sure this user doesn't already have an account... 
          invitee = User.find_by_email(user_or_email)
          if !invitee
            # every invited & fully specified email address who doesn't yet have an account will have one created for them
            invitee = User.create!({
              :name => user_or_email.split('@')[0],
              :email => user_or_email,
              :registered => true,
              :complete_profile => true,
              :password => SecureRandom.base64(15).tr('+/=lIO0', 'pqrsxyz')[0,20] #temp password
            })

            # replace email address with the user's key in the roles object

            users_with_role[users_with_role.index(user_or_email)] = "/user/#{invitee.id}" 
          end

        end
        invitee.add_to_active_in        
        UserMailer.invitation(current_user, invitee, target, invite['role'], current_subdomain, message).deliver_later

      end
    end

    roles
  end
end
