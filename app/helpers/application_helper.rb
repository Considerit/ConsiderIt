module ApplicationHelper

  def get_host
    port_string = request.port != 80 ? ':' + request.port.to_s : '' 
    "#{request.protocol}#{request.host}#{port_string}"
  end

  def get_root_domain
    reversed_host = request.host_with_port.reverse
    if reversed_host.count(':') > 1
      first_dot = reversed_host.index('.')
      request.host_with_port[-reversed_host.index('.', first_dot + 1)..reversed_host.length]
    else
      request.host_with_port
    end
  end


  def get_proposals
    proposals = []
    #TODO: do a join here instead???
    #if session.has_key?(:domain)
    #  domain = Domain.find(session[:domain])
    #  domain.domain_maps.each do |dm|
    #    proposals.push(dm.proposal)
    #  end
    #end
    #TODO: add a "show_all, :integer" field to Option 
    # that can be queried here instead
    #proposals += Proposal.where(:domain_short => 'WA state').order(:designator)
    

    return Proposal.public

  end

  def get_proposals_by_rank(metric = 'activity')
    return Proposal.public.order("#{metric} desc")
    
  end

  def has_stance(proposal)
    return current_user && current_user.positions.published.where(:proposal_id => proposal.id).count > 0
  end


  def selected_navigation(element)
    element == @selected_navigation ? "current" : ""
  end
end
