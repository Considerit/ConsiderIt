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


  ### digests

  def group_by_object(notifications)
    notifications.each_with_object({}) { |n,h| 
      case n.event_object_type
      when 'Comment'
        obj_id = n.event_object.point.id        
      end
      h[obj_id] ||= []
      h[obj_id].push(n) 
    }
  end

  def group_by_user(notifications)
    notifications.each_with_object({}) { |n,h| 
      case n.event_object_type
      when 'Point'
        obj_id = n.event_object.user_id        
      end
      h[obj_id] ||= []
      h[obj_id].push(n) 
    }
  end

  #
  # Milly Unger, Phil Simms, Jorge R., and 45 others...
  def get_user_str(notifications, max_users = 3)
    users = notifications.map {|n| n.event_object.user}.uniq
    over = users.length - max_users

    str = ""
    named = [max_users, users.length].min
    users[0..named-1].each_with_index do |user, idx|
      pp 'HOLA', "#{idx}, #{named - 1}"
      if idx == named - 1 && over <= 0 && named > 1
        str += ' and '
      end
      str += user.name
      if idx < named - 1 && named != 2
        str += ', '
      end


    end

    if over > 0
      str += " and #{over} other#{over > 1 ? 's' : ''}"
    end

    pp str
    str.gsub('  ', ' ')
  end

  def logo_red
    "#B03A44"
  end


end