class Dashboard::DashboardController < ApplicationController
  def render(*args)
    @current_page = 'dashboard'
    @dashboard = true
    super
  end

  def admin_template
    render_to_string :partial => 'dashboard/templates_dashboard'
  end
end