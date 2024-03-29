class PageController < ApplicationController

  def show
    page = params[:id] ? params[:id] : APP_CONFIG[:product_page]
    
    if page == APP_CONFIG[:product_page]

      authorize!("access forum", current_subdomain, "/page/")

      dirty_key '/page/'
      # dirty_key '/users'

    elsif page.match 'dashboard/'

      case page

      when 'dashboard/moderate'
        authorize_action = "moderate content"

      when 'dashboard/create_subdomain'
        authorize_action = "create subdomain"

      when 'dashboard/application', 'dashboard/roles', 'dashboard/data_import_export', 'dashboard/tags', 'dashboard/customizations', 'dashboard/analytics', 'dashboard/intake_questions'
        authorize_action = "update subdomain"

      when 'dashboard/edit_profile', 'dashboard/notifications', 'dashboard/translations', 'dashboard/all_forums'
        authorize_action = 'access forum'
      else
        authorize_action = nil
      end
      
      authorize!(authorize_action, current_subdomain, "/page/#{page}") if authorize_action

      dirty_key "/page/#{page}"

    elsif page != 'proposal/new' && page != 'about'

      proposal = Proposal.find_by_slug page

      if !proposal 
        render :json => {:key => "/page/#{page}", :result => 'Not found'}
        return
      end

      authorize! "read proposal", proposal, "/page/#{proposal.slug}"

      # Ensure an existing opinion for this user
      # your_opinion = Opinion.get_or_make(proposal)

      dirty_key "/page/#{proposal.slug}"
      # dirty_key '/users'
    end

    render :json => []

  end

end
