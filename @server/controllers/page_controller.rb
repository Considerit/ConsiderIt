class PageController < ApplicationController
  respond_to :json

  def show
    page = params[:id] ? params[:id] : 'homepage'
    
    if page == 'homepage'

      authorize!("access forum", current_subdomain, "/page/")

      dirty_key '/page/'
      dirty_key '/users'

    elsif page.match 'dashboard/'

      case page

      when 'dashboard/moderate'
        authorize_action = "moderate content"

      when 'dashboard/create_subdomain'
        authorize_action = "create subdomain"

      when 'dashboard/application', 'dashboard/roles', 'dashboard/import_data', 'dashboard/tags', 'dashboard/customizations'
        authorize_action = "update subdomain"

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
      dirty_key '/users'
    end

    render :json => []

  end

end
