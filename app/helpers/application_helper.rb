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

end
