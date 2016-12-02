module MailerHelper

  def section(name)
    if @part == 'text'
      "\r\n=============\r\n#{name.capitalize}\r\n=============\r\n\r\n"
    else 
      """
      <tr>
      <td style='background-color: #ffffff; padding: 18px 24px 24px 24px; text-align: left; box-shadow:0px 1px 2px rgba(0,0,0,.3)'>
      <h2 style='color:#434343; text-align: left; font-size:24px; margin: 0; padding: 0; font-weight: 400'>#{name}</h2>
      <div style='color: #434343; text-align: left'>
      """.html_safe
    end

  end 

  def end_section
    if @part == 'text'
      return ''
    else 
      '</div></td></tr>'.html_safe
    end

  end

  def proposal_with_events(proposal)
    header = proposal_header(proposal, true)
    if @part == 'text'
      header
    else 
      html = "<table><tr><td style='padding-top: 15px; padding-bottom: 15px'>"
      html += header
      html += '</td></tr></table>'
      html.html_safe 
    end 
  end 

  def proposal_without_events(proposal)
    header = proposal_header({:obj => proposal}, false)

    if @part == 'text'
      header
    else 
      html = "<table><tr><td style='padding-top: 8px; padding-bottom: 8px'>"
      html += header
      html += '</td></tr></table>'
      html.html_safe 
    end
  end 

  def relationship(rel)
    if @part == 'text'
      "*#{rel}*"
    else 
      """ <span style='vertical-align:baseline;background-color:#FE1394;color:#ffffff;font-size:13px;font-weight:500;padding:1px'>
        #{rel.gsub(' ', '&nbsp;')}
      </span>"""
    end
  end 

  def avatar(user, size=30, circular=false)
    return '' if @part == 'text' || true

    if user.avatar_file_name
      if size > 30 
        img_type = 'large'
      else 
        img_type = 'small'
      end 

      "<img title='#{user.name}' style='#{circular ? 'border-radius:50%;' : ''} width: #{size}px; height: #{size}px' src='#{user.avatar_link(img_type)}'></img>"
    else 
      "<div title='#{user.name}' style='background-color:#aaa;#{circular ? 'border-radius:50%;' : ''} width:#{size}px;height:#{size}px'> </div>"
    end 

  end 

  def proposal_header(proposal_info, with_events)
    proposal = proposal_info[:obj]
    points = proposal.points.published.named 
    opinions = proposal.opinions.published
    has_relationship = proposal_info.key?(:relationship) && proposal_info[:relationship]

    if @part == 'text'
      text = "\r\n\r\n--------------------------------------------\r\n#{proposal.name}\r\n--------------------------------------------\r\n"
      text += "by #{proposal.user.name}, #{time_ago_in_words(proposal.created_at)} ago  •  #{points.count} #{points.count == 1 ? 'point' : 'points'}  •  #{opinions.count} #{opinions.count == 0 ? 'opinion' : 'opinions'}\r\n"
      if has_relationship
        text += relationship(proposal_info[:relationship])
      end
      text += "\r\nview full proposal at #{full_link(proposal.slug)}\r\n\r\n"

      if with_events && proposal_info.key?(:events)
        text += proposal_events proposal_info[:events].values()
      end 
      text
    else 
      html = ''
      # html = "<div style='position:relative; margin-top:20px'>"

      # html += "<div style='position:absolute;left:-52px;top:4px;'>"
      # html += avatar(proposal.user, 40)
      # html += '</div>'
      html += "<a style='font-weight:600;color: #439fe0;text-decoration:underline; font-size:20px;' href='#{full_link(proposal.slug)}'>#{proposal.name.strip}</a>"
      if has_relationship
        html += relationship(proposal_info[:relationship])
      end
      html += "<div style='color:#7D7D7D;font-size:14px;'>by #{proposal.user.name}, #{time_ago_in_words(proposal.created_at)} ago  •  #{points.count} #{points.count == 1 ? 'point' : 'points'}  •  #{opinions.count} #{opinions.count == 0 ? 'opinion' : 'opinions'}</div>"
      html += ""

      if with_events && proposal_info.key?(:events)
        html += proposal_events proposal_info[:events].values()
      end 
      # html += "</div>"
      html.html_safe
    end
  end 

  def proposal_events(events)

    events.sort_by! do |ev| 
      case ev[:type] 
      when 'new_opinion'
        1
      when 'new_inclusion'
        2
      when 'new_point'
        3
      when 'new_comment'
        4
      else 
        5
      end
    end 

    if @part == 'text'
      text = "New activity:\r\n"
    else 
      html = "<table><tr><td style='padding-left:30px'><table>"
    end 

    events.each do |ev|
      case ev[:type] 
      when 'new_opinion'
        label = 'added their opinion'
      when 'new_inclusion'
        if ev[:users].length == 1
          label = 'agrees with:'
        else 
          label = 'agree with:'
        end
      when 'new_point'
        label = "added a new #{ev[:obj].category}:"
      when 'new_comment'
        label = 'commented on:'
      else 
        label = ev[:type]
      end

      if @part == 'text'
        text += "\r\n\r\n#{people_list(ev[:users])} #{label}" 

        if ev.key?(:obj)
          text += "\r\n"
          if ev.key?(:relationship)
            text += point_link(ev[:obj], ev[:relationship])
          else 
            text += point_link(ev[:obj])
          end
        end
      else
        html += "<tr><td style='min-height: 30px; padding-top:12px;'>"
        html += facepile ev[:users]
        html += """<div style='color:#434343;font-size:14px;'>#{people_list(ev[:users])} #{label}</div>""" 
        if ev.key?(:obj)
          if ev.key?(:relationship)
            html += point_link(ev[:obj], ev[:relationship])
          else 
            html += point_link(ev[:obj])
          end
        end
        html += '</td></tr>'
      end 
    end

    if @part == 'text'
      text
    else 
      html += '</table></td></tr></table>'
      html
    end
  end

  def facepile(users)
    return ''

    html = ''
    zindex = 99
    users.sort! {|a,b| a.avatar_file_name ? -1 : 1}
    users.each_with_index do |user, idx|
      html += "<div style='border-radius:50%; border:1px solid white; height:30px; width:30px; position:absolute; z-index:#{zindex - idx}; left:#{-42 - 4 * idx}px;'>"
      html += avatar(user, 30, true)
      html += '</div>'
    end 
    html
  end 

  def point_link(point, relationship=false)

    if @part == 'text'
      text = "'#{point.title(70)}'"
      if relationship
        text += ' '
        text += relationship(relationship)
        text += "\r\n"
      end
      text += "\r\nView at #{full_link(point.proposal.slug, {results: true, selected: "%2Fpoint%2F#{point.id}"})}"
      text
    else 
      html = """&ldquo;<a style='font-weight:600;color: #434343;text-decoration:underline; font-weight: 500; font-size:16px;' 
                 href='#{full_link(point.proposal.slug, {results: true, selected: "%2Fpoint%2F#{point.id}"})}'>#{point.title(90)}</a>&rdquo;"""
      if relationship
        html += relationship(relationship)
      end
      html
    end
  end

  def people_list(users, max_users = 1)
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

  def full_link(relative_path, query_params = nil)
    query_params ||= {}
    user = @user || @notification.user
    subdomain = @subdomain || @notification.subdomain

    query_params.update({
      u: user.email,
      t: user.auth_token(subdomain)
    })

    query_params = query_params.map{|k,v| "#{k}=#{v}"}.join('&')

    #pp "#{Rails.env.development? ? 'http://' : 'https://'}#{subdomain.host_with_port}/#{relative_path}?#{query_params}"
    
    "#{Rails.env.development? ? 'http://' : 'https://'}#{subdomain.host_with_port}/#{relative_path}?#{query_params}"    
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


  def styled_link(href, anchor, options = {})
    anchor ||= href
    if @part == 'text'
      "#{options[:text_preceding]}#{options[:text_instead] ? anchor : full_link(href, options[:search_params])}"
    else
      "<a href=#{full_link(href, options[:search_params])} style='font-weight: 700; color:#439fe0;'>#{anchor}</a>".html_safe
    end
  end


end