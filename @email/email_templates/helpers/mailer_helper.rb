module MailerHelper
  def full_link(relative_path, query_params = {})
    user = @user || @notification.user
    subdomain = @subdomain || @notification.subdomain

    query_params.update({
      u: user.email,
      t: ApplicationController.MD5_hexdigest("#{user.email}#{user.unique_token}#{subdomain.name}")
    })

    query_params = query_params.map{|k,v| "#{k}=#{v}"}.join('&')

    #pp "#{Rails.env.development? ? 'http://' : 'https://'}#{subdomain.host_with_port}/#{relative_path}?#{query_params}"
    
    "#{Rails.env.development? ? 'http://' : 'https://'}#{subdomain.host_with_port}/#{relative_path}?#{query_params}"    
  end
end