module MailerHelper

  def section(name)
    section_name = translator({
        id: "email.digest.section_heading.#{name.capitalize.gsub(' ','_')}"
      }, name.capitalize)

    if @part == 'text'
      "\r\n\r\n=============\r\n#{section_name}\r\n============="
    else 
      """
      <tr>
      <td style='background-color: #ffffff; padding: 18px 24px 24px 24px; text-align: left; box-shadow:0px 1px 2px rgba(0,0,0,.3)'>
      <h2 style='color:#434343; text-align: left; font-size:24px; margin: 0; padding: 0; font-weight: 400'>#{section_name}</h2>
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
    rel_text = translator("email.digest.relationship.#{rel}", rel)
    if @part == 'text'
      "*#{rel_text}*"
    else 
      """ <span style='vertical-align:baseline;background-color:#FE1394;color:#ffffff;font-size:13px;font-weight:500;padding:1px'>
        #{rel_text.gsub(' ', '&nbsp;')}
      </span>"""
    end
  end 







  def time_ago(timestamp)
    timestamp_translation = translator({id: "email.digest.proposal_timestamp", T: timestamp.to_datetime}, "at {T, time, short} on {T, date, full}")
    if @translation_lang == 'en'
      "#{time_ago_in_words(timestamp)} ago"
    else
      timestamp_translation
    end 
  end 

  def proposal_header(proposal_info, with_events)
    proposal = proposal_info[:obj]
    points = proposal.points.published.named 
    opinions = proposal.opinions.published
    has_relationship = proposal_info.key?(:relationship) && proposal_info[:relationship]

    author_text = translator({id: 'email.digest.proposal_author', author: proposal.user.name}, "by {author}")
    points_count = translator({id: 'email.digest.points_count', cnt: points.count}, "{ cnt, plural,
                    =0 {no points}
                    one {# point}
                    other {# points}
                  }")

    opinions_count = translator({id: 'email.digest.points_count', cnt: opinions.count}, "{ cnt, plural,
                    =0 {no opinions}
                    one {# opinion}
                    other {# opinions}
                  }")

    by_text = "#{author_text}, #{time_ago(proposal.created_at)}  •  #{points_count}  •  #{opinions_count}"

    if @part == 'text'
      text = "\r\n\r\n--------------------------------------------\r\n#{proposal.name}\r\n--------------------------------------------\r\n"
      text += "#{by_text}\r\n"
      if has_relationship
        text += relationship(proposal_info[:relationship])
      end

      view_text = translator(
        {id: "email.digest.proposal_link.text", link: full_link(proposal.slug)}, 
        "view full proposal at {link}")
      text += "\r\n#{view_text}\r\n\r\n"

      if with_events && proposal_info.key?(:events)
        text += proposal_events proposal_info[:events].values()
      end 
      text

    else 
      html = ''

      html += "<a style='font-weight:600;color: #439fe0;text-decoration:underline; font-size:20px;' href='#{full_link(proposal.slug)}'>#{proposal.name.strip}</a>"
      if has_relationship
        html += relationship(proposal_info[:relationship])
      end
      html += "<div style='color:#7D7D7D;font-size:14px;'>#{by_text}</div>"
      html += ""

      if with_events && proposal_info.key?(:events)
        html += proposal_events proposal_info[:events].values()
      end 

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
      text = translator("email.digest.proposal_activity.text", "New activity") + ":\r\n"
    else 
      html = "<table><tr><td style='padding-left:30px'><table>"
    end 

    events.each do |ev|
      point_type = nil
      case ev[:type] 
      when 'new_opinion'
        label = 'added their opinion'
      when 'new_inclusion'
        label = "{ people_count, plural, 
                     one {agrees with:} 
                     other {agree with} }"
      when 'new_point'
        point_type = ev[:obj].category
        label = "added a new {point_type}:"
      when 'new_comment'
        label = 'commented on:'
      else 
        label = ev[:type]
      end

      event_heading = translator({
        id: "email.digest.event_heading.#{ev[:type]}", 
        point_type: point_type,
        people_list: people_list(ev[:users]), 
        people_count: ev[:users].length}, 
        "{people_list} " + label)

      if @part == 'text'
        text += "\r\n\r\n#{event_heading}" 

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
        html += """<div style='color:#434343;font-size:14px;'>#{event_heading}</div>""" 
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


  def point_link(point, relationship=false)

    if @part == 'text'
      text = "'#{point.title(70)}'"
      if relationship
        text += ' '
        text += relationship(relationship)
        text += "\r\n"
      end
      translated_link = translator(
        {id: "email.digest.point_link.text", link: full_link(point.proposal.slug, {results: true, selected: "%2Fpoint%2F#{point.id}"})}, 
        "View at {link}")
      text += "\r\n#{translated_link}"
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

  def people_list(users)
    if users.length > 1
      translator({id: "email.digest.people_list", name: users[0].name, cnt: users.length}, 
                "{name} and { cnt, plural,
                  one {one other}
                  other {# others}
                 }")
    else 
      users[0].name
    end
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




  ############
  # unused methods:

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


end