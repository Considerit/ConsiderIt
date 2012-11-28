class Dashboard::DashboardController < ApplicationController
  def render(*args)
    @current_page = 'dashboard'
    @dashboard = true
    super
  end
end