class SubdomainController < ApplicationController
  respond_to :json
  skip_before_action :verify_authenticity_token, :only => :update_images_hack

  def new
    render :json => []
  end

  def create
    authorize! :create, Subdomain

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
    authorize! :update, subdomain
    if subdomain.id != current_subdomain.id #&& !current_user.super_admin
      # for now, don't allow modifying non-current subdomain
      raise new AccessDenied
    end

    fields = ['moderate_points_mode', 'moderate_comments_mode', 'moderate_proposals_mode', 'about_page_url', 'notifications_sender_email', 'app_title', 'external_project_url', 'has_civility_pledge']
    attrs = params.select{|k,v| fields.include? k}

    if params.has_key?('roles') && params[:send_email_invite]
      # detect who was added so we can send them an email invite
      message = nil 
      if params.has_key?('custom_email_message') && params['custom_email_message'] && params['custom_email_message'].length > 0
        message = params['custom_email_message']
      end
      current_roles = subdomain.user_roles
      current_roles.keys.each do |role|
        if params['roles'].has_key?(role)        
          diff = Set.new(params['roles'][role]) - Set.new(current_roles[role])
          if diff.length > 0
            diff.each do |user_or_email|
              if user_or_email[0] == '/'
                invitee = User.find(key_id(user_or_email))
              else 
                # let's first just check to make sure this user doesn't already have an account... 
                invitee = User.find_by_email(user_or_email)
                if !invitee
                  # create a new user to send an invite too...
                  invitee = User.create!({
                    :email => user_or_email,
                    :registered => true,
                    :password => SecureRandom.base64(15).tr('+/=lIO0', 'pqrsxyz')[0,20] #temp password
                  })
                end
              end

              params['roles'][role][params['roles'][role].index(user_or_email)] = "/user/#{invitee.id}"
              UserMailer.invitation(current_user, invitee, current_subdomain, role, current_subdomain, message).deliver!
            end
          end
        end
      end
    end

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