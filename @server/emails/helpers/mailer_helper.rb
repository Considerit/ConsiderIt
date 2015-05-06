module MailerHelper
  def full_link(relative_path, query_params = {})    
    query_params.update({
      u: @notification.user.email,
      t: ApplicationController.MD5_hexdigest("#{@notification.user.email}#{@notification.user.unique_token}#{@notification.subdomain.name}")
    })

    query_params = query_params.map{|k,v| "#{k}=#{v}"}.join('&')

    #pp "#{Rails.env.development? ? 'http://' : 'https://'}#{@notification.subdomain.host_with_port}/#{relative_path}?#{query_params}"
    
    "#{Rails.env.development? ? 'http://' : 'https://'}#{@notification.subdomain.host_with_port}/#{relative_path}?#{query_params}"    
  end
end