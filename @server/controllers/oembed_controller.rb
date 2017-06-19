require 'uri'

class OembedController < ApplicationController
  respond_to :html
  
  def show

    url = params[:url]
    begin
      u = URI.parse(url)
    rescue URI::InvalidURIError  # happens when subdomain contains an underscore
      host = url.match(".+\:\/\/([^\/]+)")[1]
      u = URI.parse(url.sub(host, 'dummy-host'))
      u.instance_variable_set('@host', host)
    end

    slug = u.path.gsub /\//, '' 
    proposal = Proposal.find_by_slug slug

    if !proposal
      render :file => "#{Rails.root}/public/404.html", :layout => false, :status => :not_found
      return
    end

    authorize! "read proposal", proposal

    width = params[:maxwidth].to_i

    width = 700 if width == 0 || !width || width > 700 

    # don't actually support height. Twitter doesn't either :)
    # https://dev.twitter.com/rest/reference/get/statuses/oembed
    height = 326

    # guess the height
    width_per_char = 490.0 / 45 + 1
    line_wrap_penalty = 15 * width_per_char 
    line_width = width - 40 - line_wrap_penalty
    lines = proposal.name.length * width_per_char / line_width.to_f
    lines = lines.ceil
    lines -= 1 # first line is already factored in
    line_height = lines * 29 + 6 * lines 
    height += line_height

    format = params[:format] or 'json'

    port = u.port != 80 && u.port != 443 ? ":#{u.port}" : ''
    embed_src = "#{u.scheme}://#{u.host}#{port}/embed/proposal/#{proposal.slug}"

    attrs = {
      :src => embed_src,
      :width => width,
      :height => height,
      :frameborder => 0,
      :style => "overflow:hidden",
      :scrolling => 'no'
    }

    attributes = []
    attrs.each do |k,v|
      attributes.append "#{k}='#{v}'"
    end

    resp = {
      :version => '1.0',
      :title => proposal.name,
      :author_name => proposal.user.name,
      :provider_url => 'https://consider.it',
      :provider_name => 'Consider.it',
      :type => 'rich',
      :width => width,
      :height => height,
      :html => """<iframe id='considerit-embed-#{proposal.id}' #{attributes.join(' ')}></iframe>
        <script src='https://cdnjs.cloudflare.com/ajax/libs/iframe-resizer/3.5.14/iframeResizer.min.js'></script>
        <script type='application/javascript'>
          var resize_interval=setInterval(function(){
            if (typeof iFrameResize != 'undefined'){
              iframe = document.getElementById('considerit-embed-#{proposal.id}')
              iFrameResize({log:true, checkOrigin:false}, iframe)
              iframe.iFrameResizer.sendMessage('Houston, we have contact!')
              clearInterval(resize_interval)
            }
          }, 40)
        </script>"""
    }

    @oembed_request = true

    ActiveSupport.escape_html_entities_in_json = false

    respond_to do |format|
      format.html { render :json => resp.to_json }
      format.json { render :json => resp.to_json }
      format.xml  { render :xml => resp.to_xml(:root => "oembed") }
    end 

    Rails.logger.info resp.to_json
    
    ActiveSupport.escape_html_entities_in_json = true
  
  end


  def proposal_embed

    @oembed_request = true

    # if someone has accessed a non-existent subdomain or the mime type isn't HTML (must be accessing a nonexistent file)
    @proposal = Proposal.find_by_slug params[:slug]

    if !@proposal || permit("read proposal", @proposal) < 0 || !current_subdomain || request.format.to_s != 'text/html' || request.fullpath.include?('data:image')
      @not_found = true
    end

    manifest = JSON.parse(File.open("public/build/manifest.json", "rb") {|io| io.read})

    if Rails.application.config.action_controller.asset_host
      @js = "#{Rails.application.config.action_controller.asset_host}/#{manifest['proposal_embed']}"
    else 
      @js = "/#{manifest['proposal_embed']}"
    end

    dirty_key '/asset_manifest'
    response.headers["Strict Transport Security"] = 'max-age=0'

    render "layouts/proposal_embed", :layout => false
  end

  def allow_iframe_requests
    response.headers.delete('X-Frame-Options')
  end  

end