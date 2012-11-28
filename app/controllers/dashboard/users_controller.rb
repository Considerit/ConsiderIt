class Dashboard::UsersController < Dashboard::DashboardController

  def show
    @sidebar_context = :user
    @selected_navigation = :profile
    @user = User.find(params[:id])

  end

  def edit
    @sidebar_context = :user_profile
    @selected_navigation = :profile

    #TODO: authorize for edit profile
  end

  def edit_account
    @sidebar_context = :user_profile
    @selected_navigation = :account
    #TODO: authorize for edit profile
  end

  def edit_notifications
    @sidebar_context = :user_profile
    @selected_navigation = :notifications
    #TODO: authorize for edit profile
  end


end