module Invitations
end

class SubdomainController < ApplicationController
  respond_to :json
  skip_before_action :verify_authenticity_token, :only => :update_images_hack
  include Invitations

  def index 
    subdomains = Subdomain.where('name != "homepage"').map {|s| {:id => s.id, :name => s.name}}
    render :json => [{
      key: '/subdomains',
      subs: subdomains
    }]

  end

  def create
    authorize! 'create subdomain'

    errors = []

    # TODO: sanitize / make sure has url-able characters
    subdomain = params[:subdomain]

    existing = Subdomain.find_by_name(subdomain)
    if existing
      errors.push "The #{subdomain} subdomain already exists. Contact us for more information."
    else
      new_subdomain = Subdomain.new :name => subdomain
      roles = new_subdomain.user_roles
      roles['admin'].push "/user/#{current_user.id}"
      roles['visitor'].push "*"
      new_subdomain.roles = JSON.dump roles
      new_subdomain.save
    end

    if errors.length > 0
      render :json => [{errors: errors}]
    else
      render :json => [{name: new_subdomain.name}]
    end
  end

  def show
    dirty_key '/subdomain'
    render :json => []
  end

  def update
    subdomain = Subdomain.find(params[:id])
    authorize! 'update subdomain', subdomain

    if subdomain.id != current_subdomain.id #&& !current_user.super_admin
      # for now, don't allow modifying non-current subdomain
      raise PermissionDenied.new Permission::DISABLED
    end

    fields = ['moderate_points_mode', 'moderate_comments_mode', 'moderate_proposals_mode', 'about_page_url', 'notifications_sender_email', 'app_title', 'external_project_url', 'has_civility_pledge']
    attrs = params.select{|k,v| fields.include? k}

    update_roles

    serialized_fields = ['roles', 'branding']
    for field in serialized_fields
      if params.has_key? field
        attrs[field] = JSON.dump params[field]
      end
    end

    current_user.add_to_active_in
    current_subdomain.update_attributes! attrs

    dirty_key '/subdomain'
    render :json => []

  end

  def update_roles
    if params.has_key?('roles')
      if params.has_key?(:invitations) && params[:invitations]
        params['roles'] = process_and_send_invitations(params['roles'], params[:invitations], current_subdomain)
      end
      # rails replaces [] with nil in params for some reason...
      params['roles'].each do |k,v|
        params['roles'][k] = [] if !v
      end
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
              :password => SecureRandom.base64(15).tr('+/=lIO0', 'pqrsxyz')[0,20] #temp password
            })
            invitee.add_to_active_in

            # replace email address with the user's key in the roles object
            users_with_role[users_with_role.index(user_or_email)] = "/user/#{invitee.id}"

          end
        end
        UserMailer.invitation(current_user, invitee, target, invite['role'], current_subdomain, message).deliver_later

      end
    end

    roles
  end
end
