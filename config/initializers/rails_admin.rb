require "rails_admin/application_controller"

# RailsAdmin.authorize_with do
#  redirect_to root_path unless current_user.admin?
# end

=begin
module RailsAdmin
  class ApplicationController < ::ApplicationController
    filter_access_to :all
  end
end

authorization do
  role :admin do
    has_permission_on :rails_admin_history, :to => [:list, :slider, :for_model, :for_object]
    has_permission_on :rails_admin_main, :to => [:index, :show, :new, :edit, :create, :update, :destroy, :list, :delete, :bulk_delete, :bulk_destroy, :get_pages, :show_history]
  end
end
=end
