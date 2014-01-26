xml.instruct! :xml, :version => "1.0" 
xml.rss :version => "2.0" do
  xml.channel do
    xml.title "#{current_tenant.app_title}"
    xml.description ""
    xml.link root_url

    for action in @actions
      xml.item do
        xml.title action.title
        xml.description action.description
        xml.pubDate action.created_at.to_s(:rfc822)
        xml.link action.url(request.host_with_port)
        #xml.guid action_url(action)
      end
    end
  end
end