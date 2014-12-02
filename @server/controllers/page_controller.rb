class PageController < ApplicationController
  respond_to :json

  def show
    page = params[:id]

    to_dirty = []
    access_denied = nil
    
    if page == 'homepage'
      to_dirty.append '/page/homepage'
      to_dirty.append '/users'

    elsif page.match 'dashboard/'

      case page
      when 'dashboard/assessment'
        if cannot? :index, Assessment
          access_denied = 'login required'
        end
      when 'dashboard/moderate'
        if cannot? :index, Moderation
          access_denied = 'login required'
        end
      when 'dashboard/create_subdomain'
        if cannot? :create, Subdomain
          access_denied = 'login required'
        end
      when 'dashboard/import_data'
        if !current_user.is_admin?
          access_denied = 'login required'
        end
      when 'dashboard/application', 'dashboard/roles'
        if cannot? :update, Subdomain
          access_denied = 'login required'
        end
      else
        permitted = true
      end

      if !access_denied
        to_dirty.append "/page/#{page}"
      end


    elsif page == 'proposal/new' || page == 'about' # don't need anything special
      noop = 1

    else # if proposal

      proposal = Proposal.find_by_slug page

      if !proposal 
        render :status => :not_found, :json => {:result => 'Not found'}
        return
      end

      if cannot? :read, proposal
        # TODO: get real reason
        access_denied = 'login required'
      end

      # Ensure an existing opinion for this user
      your_opinion = Opinion.get_or_make(proposal, current_user)

      to_dirty.append "/page/#{proposal.slug}"
      to_dirty.append '/users'
    end

    if access_denied
      render :status => :forbidden, :json => {:access_denied => access_denied}
    else
      to_dirty.each do |key| 
        dirty_key key
      end

      render :json => []
    end


  
  end

end
