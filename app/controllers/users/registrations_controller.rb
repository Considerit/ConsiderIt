class Users::RegistrationsController < Devise::RegistrationsController
	protect_from_forgery :except => :create

  def new
    @context = params[:context]
    super
  end

  def create
    build_resource

    if resource.save
      if resource.active_for_authentication?
        sign_in(resource_name, resource)
        if current_user && session[:domain] != current_user.domain_id
          current_user.domain_id = session[:domain]
          current_user.save
        end
        if session.has_key?('position_to_be_published')
          session['reify_activities'] = true 
        end
        redirect_to request.referer

      else
        set_flash_message :notice, :inactive_signed_up, :reason => inactive_reason(resource) if is_navigational_format?
        expire_session_data_after_sign_in!
        respond_with resource, :location => after_inactive_sign_up_path_for(resource)
      end
    else
      clean_up_passwords(resource)
      respond_with_navigational(resource) { render_with_scope :new }
    end
    
  end
  def update
    current_user.avatar = params[:user][:avatar]
    current_user.save
    redirect_to request.referer
  end
end