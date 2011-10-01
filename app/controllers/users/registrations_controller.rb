class Users::RegistrationsController < Devise::RegistrationsController
	protect_from_forgery :except => :create

  def new
    @context = params[:context]
    super
  end

  def create
    super
    if current_user && session[:zip] != current_user.zip
      current_user.zip = session[:zip]
      current_user.save
    end

  end
  def update
    current_user.avatar = params[:user][:avatar]
    current_user.save
    redirect_to request.referer
  end
end