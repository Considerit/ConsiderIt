module MailerHelper
  def full_link(relative_path, query_params = nil)
    query_params ||= {}
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

    str.gsub('  ', ' ')
  end

  def logo_red
    "#B03A44"
  end

  def item_divider
    if @part == 'text'
      "\r\n      ----     \r\n"
    else
      "<hr style='border: 0; height: 1px; background-color: #ccc; background-image: linear-gradient(to right, rgb(255, 255, 255), rgb(200, 200, 200), rgb(255, 255, 255));' />".html_safe
    end

  end

  def linebreak
    if @part == 'text'
      "\r\n\r\n"
    else 
      "<div style='height: 10px'> </div>".html_safe
    end
  end

  def paragraph(text)

    if @part == 'text'
      "\r\n#{text}\r\n"
    else
      "<p style='padding: 0px 20px;' >#{text}</p>".html_safe
    end

  end

  def list_item(text)
    if @part == 'text'
      "\r\n - #{text}\r\n"
    else 
      "<div style='margin: 5px 0; padding: 0px 20px; background-color: #fff;'>#{text}</div>".html_safe
    end
  end

  def section_header_major(text)
    if @part == 'text'
      "\r\n\r\n#{'='*(text.length*2)}\r\n#{'='*text.length}#{text}#{'='*text.length}\r\n#{'='*(text.length*2)}\r\n\r\n"
    else 
      "<div style='font-weight: 600;'>#{text}</div>".html_safe
    end
  end

  def section_header(text)
    if @part == 'text'
      "\r\n#{text}\r\n#{'-'*text.length}\r\n"
    else 
      "<div style=''>* #{text} *</div>".html_safe
    end
  end

  def styled_link(href, anchor, options = {})
    anchor ||= href
    if @part == 'text'
      "#{options[:text_preceding]}#{options[:text_instead] ? anchor : full_link(href, options[:search_params])}"
    else
      "<a href=#{full_link(href, options[:search_params])} style='font-weight: 700; color:#{logo_red};'>#{anchor}</a>".html_safe
    end
  end


end