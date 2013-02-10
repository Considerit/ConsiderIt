
class Users::RegistrationsController < Devise::RegistrationsController

  #TODO: reevaluate whether this exception is still needed
  # it works fine without, but need to check if it works when creating account from omniauth
	protect_from_forgery #:except => :update

  # deprecated
  # todo: handle pinned user on client
  def new
    @context = params[:context] 
    if params.has_key?(:user) && params.has_key?(:token) && params[:token]
      if ApplicationController.arbitrary_token("#{params[:user]}#{current_tenant.identifier}") == params[:token]
        @pinned_user = params[:user]
      end
    end
    
    store_location request.referer unless params[:redirect_already_set] == 'true'   
    super
  end

  def create
    user = User.find_by_email(params[:user][:email])

    if user && user.valid_password?(params[:user][:password])
      sign_in(resource_name, user)
      # if session.has_key?('position_to_be_published')
      #   session['reify_activities'] = true 
      # end    

      #TODO: handle domains / zipcodes / addresses in client
      #if current_user && session.has_key?(:domain) && session[:domain] && !current_user.tags.include?(session[:domain])
      #  current_user.tags = params[:domain] 
      #  current_user.save
      #elsif current_user && current_user.tags
      #  session[:domain] = current_user.tags
      #end

      response = { 
        :result => 'logged_in',
        :reason => 'email_password_success'
      }

    elsif user

      response = {
        :result => 'rejected',
        :reason => 'user_exists'
      }

    else
      user = build_resource
      user.referer = session[:referer] if session.has_key?(:referer)
      if user.save
        sign_in(resource_name, user)
        current_user.track!

        # if current_user && session.has_key?(:domain) && session[:domain] && !current_user.tags.include?(session[:domain])
        #   current_user.tags = params[:domain] 
        #   current_user.save
        # end

        # if session.has_key?('position_to_be_published')
        #   session['reify_activities'] = true 
        # end
        # set_flash_message :notice, :signed_up
        #redirect_to request.referer
        # redirect_to session[:return_to] || root_path
        response = {
          :result => 'successful',
          #TODO: filter users' to_json
          :user => current_user.to_json
        }

      else
        response = {
          :result => 'rejected',
          :reason => 'validation error'
        }

      end 
    end
    render :json => response

  end

  def update
    # not using skip confirmation because it sets confirmed_at on additional info provisioning...not sure why it was enabled
    #current_user.skip_confirmation!

    # TODO: explicitly grab params
    if current_user.update_attributes(params[:user])

      
      #sign_in @user, :bypass => true if params[:user].has_key?(:password)
      render :json => {
        :result => 'successful',
        #TODO: filter users' to_json
        :user => current_user.to_json
      }
    else 
      render :json => {
        :result => 'failed',
        :reason => 'could not save user'
      }
    end

    #current_user.skip_confirmation!
    #current_user.save

    #if params[:user].has_key?(:proposal_id)
    #  # this is for caching purposes, particularly the histogram
    #  Proposal.find_by_id(params[:user].delete(:proposal_id)).touch
    #end
    #redirect_to !request.referer.nil? ? request.referer : root_path

  end

  def destroy
    resource.destroy
    Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name)
    render :json => { :result => 'successful', :new_csrf => form_authenticity_token }
  end


  # DEPRECATED
  #def check_login_info    
  #  email = params[:user][:email]
  #  password = params[:user][:password]

  #  user = User.find_by_email(email)
  #  email_in_use = !user.nil?

  #  render :json => { :valid => !email_in_use || user.valid_password?(password) }
  #end

end