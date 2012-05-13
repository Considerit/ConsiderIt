module ApplicationHelper
  
  def get_available_domains
    domains = []
    Domain.all.each do |d|
      domains.push("#{d.identifier}")
    end
    return domains
  end

  def get_host
    port_string = request.port != 80 ? ':' + request.port.to_s : '' 
    "http://#{request.host}#{port_string}"
  end

  def get_root_domain
    reversed_host = request.host_with_port.reverse
    first_dot = reversed_host.index('.')
    request.host_with_port[-reversed_host.index('.', first_dot + 1)..reversed_host.length]
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
    

    return Proposal.all

  end

  def get_proposals_by_rank
    proposals = Proposal.order("score desc")
    proposals
  end

  def get_proposals_by_domain
    proposals = []
    #TODO: do a join here instead???
    if session.has_key?(:domain)
     domain = Domain.find(session[:domain])
     domain.domain_maps.each do |dm|
       proposals.push(dm.proposal)
     end
    end
    # TODO: add a "show_all, :integer" field to Option 
    # that can be queried here instead
    proposals += Proposal.where(:domain => 'all').order(:designator)
    proposals
  end

  def has_stance(proposal)
    return current_user && current_user.positions.published.where(:proposal_id => proposal.id).count > 0
  end


  ## modified from: https://github.com/ryanb/complex-form-examples/blob/master/app/helpers/application_helper.rb
  def link_to_remove_fields(name, f)
    f.hidden_field(:_destroy) + link_to_function(name, "remove_fields(this)")
  end
  
  def link_to_add_fields(name, f, association, partial, mclass)
    new_object = f.object.class.reflect_on_association(association).klass.new
    fields = f.fields_for(association, new_object, :child_index => "new_#{association}") do |builder|
      render(partial, :f => builder)
    end
    link_to_function(name, "add_fields(this, \"#{association}\", \"#{escape_javascript(fields)}\")", :class => mclass)
  end

  def stance_name (bucket)
    case bucket
      when 'all'
        return ''
      when 0
        return "strong opposers"
      when 1
        return "opposers"
      when 2
        return "mild opposers"
      when 3
        return "neutral parties"
      when 4
        return "mild supporters"
      when 5
        return "supporters"
      when 6
        return "strong supporters"
    end
  end    

end
