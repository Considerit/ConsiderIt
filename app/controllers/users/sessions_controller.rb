
class Users::SessionsController < Devise::SessionsController
  #TODO: reevaluate whether this exception is still needed
  protect_from_forgery #:except => :create

  def create
    user = User.find_by_email(params[:user][:email])
    if user && user.valid_password?(params[:user][:password])
      self.resource = warden.authenticate!(auth_options)
      sign_in resource_name, resource
      response = {
        :result => 'successful',
        #TODO: filter users' to_json
        :user => current_user,
        :follows => current_user.follows.all
      }
    elsif user
      response = {
        :result => 'failure',
        :reason => 'wrong password'
      }
    else
      response = {
        :result => 'failure',
        :reason => 'no user'
      }

    end
    render :json => response
  end

  def destroy
    signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))
    render :json => {
      :new_csrf => form_authenticity_token
    }
  end


end

