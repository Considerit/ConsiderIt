class Users::ConfirmationsController < Devise::ConfirmationsController

  # POST /resource/confirmation
  def create
    user = User.find_by_email(params[:user][:email])
    proposal = Proposal.find_by_id(params[:proposal_id])

    UserMailer.confirmation_instructions(user, proposal, mail_options).deliver!
    #self.resource = User.send_confirmation_instructions()

    # if successfully_sent?(resource)
    #   respond_with({}, :location => after_resending_confirmation_instructions_path_for(resource_name))
    # else
    #   respond_with(resource)
    # end

    render :json => { :success => true }    
  end

  # GET /resource/confirmation?confirmation_token=abcdef
  def show
    self.resource = resource_class.confirm_by_token(params[:confirmation_token])

    if resource.errors.empty?
      if params.has_key?(:valid) && params[:valid] == 'false'
        set_flash_message(:notice, :not_confirmed) 
        resource.destroy
        Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name)
        respond_with_navigational(resource){ redirect_to after_sign_out_path_for(resource_name) }

      else
        set_flash_message(:notice, :confirmed) if is_navigational_format?
        sign_in(resource_name, resource)
        respond_with_navigational(resource){ redirect_to after_confirmation_path_for(resource_name, resource) }
      end
    else
      respond_with_navigational(resource.errors, :status => :unprocessable_entity){ render :new }
    end
  end  

end