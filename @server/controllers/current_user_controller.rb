
class CurrentUserController < DeviseController
  protect_from_forgery
  before_filter :configure_permitted_parameters
  skip_before_filter :verify_authenticity_token, :if => :file_uploaded

  # TODO: test if we need the following to support oauth transactions
  #prepend_before_filter { request.env["devise.skip_timeout"] = true }

  # Gets the current user data
  def show
    respond_to do |format|
      format.json {
        render :json => to_json_current_user
      }
    end
  end  

  # handles auth (login, new accounts, and login via reset password token) and updating user info
  def update
    errors = []

    if current_user
      # we're updating an existing user

      fields = ['avatar', 'bio', 'name', 'hide_name', 'email', 'password']
      user_attrs = params.select{|k,v| fields.include? k}
      user_attrs = ActionController::Parameters.new(user_attrs).permit!

      if current_user.update_attributes(user_attrs)
        results = to_json_current_user

        if params.has_key? :avatar
          dirty_avatar_cache   
        end

      elsif User.find_by_email(params[:email])
        # if user is trying to change their email address
        errors.append 'That email is not available.'
      else
        # some kind error happened
        errors.append 'Could not save your changes.'
      end

    else
      # we're trying to authenticate

      by_third_party = session.has_key? :access_token
      by_password_reset_token = params.has_key? :reset_password_token

      if by_password_reset_token
        params[:password_confirmation] = params[:password] if !params.has_key? :password_confirmation
        user = User.reset_password_by_token params
      elsif by_third_party
        user = User.find_by_third_party_token(session[:access_token])
      else 
        user = User.find_by_lower_email(params[:email])
      end

      # if user already exists
      if user && (by_third_party || user.valid_password?(params[:password]) ) #&& user.registration_complete 
        sign_in :user, user

      # user exists, but authentication failed
      elsif user
        errors.append 'wrong password'

      # user does not exist, try to create account
      elsif !by_third_party && !params.has_key?(:password)
        errors.append 'Error. Have you created an account yet? If not, click below.'
      
      else


        if by_third_party
          user_params =  User.params_from_third_party_token(session[:access_token]).update(params)
          is_dirty = session[:access_token].has_key?(:avatar_url) || params.has_key?(:avatar) 

        else       
          user_params =  params
          is_dirty = params.has_key?(:avatar)
        end

        user = User.new ActionController::Parameters.new(user_params).permit!
        user.referer = user.page_views.first.referer if user.page_views.count > 0

        # user.skip_confirmation! #TODO: make email confirmations actually work... (disabling here because users with accounts that never confirmed their accounts can't login after 7 days...)

        if user.save
          sign_in :user, user

          # current_user.track!

          session.delete(:access_token) if by_third_party
          if is_dirty
            dirty_avatar_cache
          end
        else
          errors.append 'Registration failed.'
        end

      end
    end


    response = to_json_current_user
    response['errors'] = errors if errors.length > 0

    #HACKY! supports local measures w/ zipcodes
    # if user && (session.has_key? :tags) && session[:tags]
    #   user.addTags session[:tags]
    # end

    if request.xhr?
      render :json => response 
    else
      # non-ajax method is used for legacy support for dash
      if errors.length == 0
        # redirect here
        if session.has_key? :redirect_after_login
          path = session[:redirect_after_login]
          session.delete :redirect_after_login
          redirect_to path
          return
        else 
          render :json => response
        end
      else
        @errors = errors
        @not_logged_in = true        
        render :template => "old/login", :layout => 'dash' 
      end
    end

  end


  def destroy
    signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))
    render :json => to_json_current_user
  end


  #TODO: activeRESTify this method
  def send_password_reset_token
    user = User.find_by_lower_email(params[:user][:email]) if params[:user][:email].strip.length > 0
    if !user.nil?
      raw, enc = Devise.token_generator.generate(User, :reset_password_token)
      user.reset_password_token   = enc
      user.reset_password_sent_at = Time.now.utc
      user.save(:validate => false)

      UserMailer.reset_password_instructions(user, raw, mail_options).deliver!
      render :json => {
        :result => 'success'
      }
    else 
      # note: returning this is a security risk as it reveals that a particular
      #       email address exists in the system or not
      render :json => {
        :errors => ["We couldn\'t find an account matching that email."]
      } 
    end

  end

  # Omniauth oauth handlers
  def facebook
    third_party_callback
  end

  def google
    third_party_callback
  end

  def google_oauth2
    third_party_callback
  end

  def twitter
    third_party_callback
  end

  def third_party_callback
    access_token = env["omniauth.auth"]
    user = User.find_by_third_party_token access_token

    if user #&& user.registration_complete
      sign_in user, :event => :authentication
      params = to_json_current_user
    else
      session[:access_token] = access_token
      params = User.params_from_third_party_token(access_token)
    end

    render :inline =>
      "<script type=\"text/javascript\">" +
      "  window.open_id_params = #{params.to_json};  " + 
      "</script>"
  end

  # /end oauth

  # def content_for_user
  #   # proposals that are written by this user; private proposals this user has access to
  #   proposals = Proposal.content_for_user(current_user) || []

  #   top = []

  #   proposals.each do |prop|
  #     top.push(prop.top_con) if prop.top_con
  #     top.push(prop.top_pro) if prop.top_pro
  #   end

  #   points = {}
  #   Point.where('id in (?)', top).public_fields.each do |pnt|
  #     points[pnt.id] = pnt
  #   end

  #   current_user.points.published.where(:hide_name => true).public_fields.each do |pnt|
  #     points[pnt.id] = pnt
  #   end

  #   respond_to do |format|
  #     format.json {
  #       render :json => {
  #         :points => points.values,
  #         :proposals => proposals,
  #         :opinions => current_user.opinions.published
  #       }
  #     }
  #   end
  # end

  # # right now this is only used by LVG for zip codes...
  # # TODO: move this to a taggable controller, and specify the model type being tagged
  # def set_tag

  #   new_tags = params[:tags].split(';')

  #   if current_user
  #     current_user.addTags new_tags, params['overwrite_type']
  #     tags = current_user.getTags()
  #   else
  #     tags = session.has_key?(:tags) ? session[:tags] : []
  #     if params['overwrite_type']
  #       types = new_tags.map{|t| t.split(':')[0]}
  #       tags.delete_if {|t| types.include?(t.split(':')[0])}
  #     end
  #     tags |= new_tags
  #     session[:tags] = tags
  #   end

  #   respond_to do |format|
  #     format.json { render :json => { :success => true, :user_tags => tags} }
  #   end
  # end  


  private

  def dirty_avatar_cache
    current = Rails.cache.read("avatar-digest-#{current_tenant.id}") || 0
    Rails.cache.write("avatar-digest-#{current_tenant.id}", current + 1)   
  end

  def to_json_current_user
    {
      key: '/current_user',
      user: current_user ? "/user/#{current_user.id}" : nil,
      email: current_user ? current_user.email : nil,
      password: nil,
      csrf: form_authenticity_token,
      follows: current_user ? current_user.follows : nil,
      avatar_url: nil,
      url: current_user ? current_user.url : nil,
      bio: current_user ? current_user.bio : nil,
      twitter_uid: nil,
      facebook_uid: nil,
      google_uid: nil,
      name: current_user ? current_user.name : nil
    }
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_in) { |u| u.permit! }
    devise_parameter_sanitizer.for(:sign_up) { |u| u.permit! }
    devise_parameter_sanitizer.for(:account_update) { |u| u.permit! }    
  end

  def file_uploaded
    params[:remotipart_submitted].present? && params[:remotipart_submitted] == "true"
  end

end

