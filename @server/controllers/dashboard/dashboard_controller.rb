class Dashboard::DashboardController < ApplicationController
  def render(*args)
    @current_page = 'dashboard'
    super
  end

  def process_admin_template
    render_to_string :partial => './admin'
  end
end