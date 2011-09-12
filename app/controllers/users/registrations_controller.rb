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
end