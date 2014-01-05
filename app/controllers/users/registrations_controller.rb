
class Users::RegistrationsController < Devise::RegistrationsController
  protect_from_forgery
  skip_before_filter :verify_authenticity_token, :if => :file_uploaded
  before_filter :configure_permitted_parameters

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up) { |u| u.permit! }
    devise_parameter_sanitizer.for(:account_update) { |u| u.permit! }
  end


  def file_uploaded
    params[:remotipart_submitted].present? && params[:remotipart_submitted] == "true"
  end

  def create

    by_third_party = session.has_key? :access_token

    user = by_third_party ? User.find_by_third_party_token(session[:access_token]) : User.find_by_lower_email(params[:user][:email])

    if user && user.registration_complete && (by_third_party || user.valid_password?(params[:user][:password]) )
      sign_in(resource_name, user)

      response = { 
        :result => 'successful',
        :reason => 'email_password_success', 
        :new_csrf => form_authenticity_token,
        #TODO: filter users' to_json?
        :user => current_user,
        :follows => current_user.follows,         
      }

    elsif user

      response = {
        :result => 'rejected',
        :reason => 'user_exists'
      }

    elsif by_third_party
      user_params = User.create_from_third_party_token(session[:access_token]).update params[:user]
      
      user = User.new ActionController::Parameters.new(user_params).permit! #build_resource user_params
      user.referer = user.page_views.first.referer if user.page_views.count > 0

      user.skip_confirmation! 

      is_dirty = user.avatar_url_provided?

      if user.save
        sign_in(resource_name, user)

        current_user.track!

        response = {
          :result => 'successful',
          #TODO: filter users' to_json?
          :user => current_user,
          :follows => current_user.follows, 
          :new_csrf => form_authenticity_token
        }

        session.delete(:access_token)
        if is_dirty
          dirty_avatar_cache     
        end

      end


    else #registration via email
      user = build_resource(sign_up_params)
      user.referer = user.page_views.first.referer if user.page_views.count > 0

      user.skip_confirmation! #TODO: make email confirmations actually work... (disabling here because users with accounts that never confirmed their accounts can't login after 7 days...)
      
      if user.save
        sign_in(resource_name, user)
        current_user.track!

        if params[:user].has_key? :avatar
          dirty_avatar_cache     
        end

        # set_flash_message :notice, :signed_up

        response = {
          :result => 'successful',
          #TODO: filter users' to_json
          :user => current_user,
          :follows => current_user.follows, 
          :new_csrf => form_authenticity_token
        }

      else
        response = {
          :result => 'rejected',
          :reason => 'validation error'
        }

      end 
    end

    #HACKY!
    if user && (session.has_key? :tags) && session[:tags]
      user.addTags session[:tags]
    end

    render :json => response

  end

  def update
    # not using skip confirmation because it sets confirmed_at on additional info provisioning...not sure why it was enabled
    #current_user.skip_confirmation!

    # TODO: explicitly grab params

    if current_user.update_attributes params[:user].permit!

      results = {
        :result => 'successful',
        #TODO: filter users' to_json
        :user => current_user
      }

      if params[:user].has_key? :avatar
        dirty_avatar_cache   
      end

      #sign_in @user, :bypass => true if params[:user].has_key?(:password)
      render :json => results
    else 
      render :json => {
        :result => 'failed',
        :reason => 'could not save user'
      }
    end

  end

  def destroy
    resource.destroy
    Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name)
    render :json => { :result => 'successful', :new_csrf => form_authenticity_token }
  end

  def check_login_info
    email = params[:email]

    user = User.find_by_lower_email(email)
    email_in_use = !user.nil?

    if email_in_use
      pp user.third_party_authenticated
      method = user.third_party_authenticated || 'email'
    else
      method = nil
    end

    render :json => { :valid => !email_in_use, :method => method }
  end

protected
  def dirty_avatar_cache
    current = Rails.cache.read("avatar-digest-#{current_tenant.id}") || 0
    Rails.cache.write("avatar-digest-#{current_tenant.id}", current + 1)   
  end
end