module MailerHelper
  def full_link(relative_path, query_params = {})    
    query_params.update({
      u: @user.email,
      t: ApplicationController.MD5_hexdigest("#{@user.email}#{@user.unique_token}#{@subdomain.name}")
    })

    query_params = query_params.map{|k,v| "#{k}=#{v}"}.join('&')

    pp "#{@subdomain.host_with_port}/#{relative_path}?#{query_params}"
    
    "#{@subdomain.host_with_port}/#{relative_path}?#{query_params}"    
  end
end