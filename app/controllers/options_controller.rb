class OptionsController < ApplicationController
  def show
    @user = current_user
    @option = Option.find(params[:id])
  end

end
