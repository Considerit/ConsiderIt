class Users::RegistrationsController < Devise::RegistrationsController
	protect_from_forgery :except => :create

  def new
    @context = params[:context]
    super
  end

  def create
    super
    if current_user && session[:domain] != current_user.domain_id
      current_user.domain_id = session[:domain]
      current_user.save
    end
    redirect_to request.referer
  end
  def update
    current_user.avatar = params[:user][:avatar]
    current_user.save
    redirect_to request.referer
  end
end