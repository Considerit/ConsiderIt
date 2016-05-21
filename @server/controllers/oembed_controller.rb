require 'cgi'
require 'uri'

class OembedController < ApplicationController
  respond_to :html
  
  def show

    width = maxwidth = params[:maxwidth] 
    if !width
      width = 600
    end
    height = maxheight = params[:maxheight] 
    if !height 
      height = 400
    end

    format = params[:format] or 'json'  # need to support xml too

    url = CGI.unescape params[:url]
    slug = /\/\/[\d\w.:]+\/([\d\w\-_]+)/.match(url)[1]
    proposal = Proposal.find_by_slug slug


    u = URI.parse(params[:url])

    port = u.port != 80 && u.port != 443 ? ":#{u.port}" : ''
    pp u, u.scheme, u.host, u.port
    embed_src = "#{u.scheme}://#{u.host}#{port}/embed/proposal/#{proposal.slug}"

    # todo: access permission

    resp = {
      :version => '1.0',
      :title => proposal.name,
      :author_name => proposal.user.name,
      :provider_url => 'https://consider.it',
      :provider_name => 'Consider.it',
      :type => 'rich',
      :width => width,
      :height => height,
      :html => "<iframe style='border:none; outline:none;' width='#{width}' height='#{height}' src='#{embed_src}'></iframe>"
    }

    @oembed_request = true


    ActiveSupport.escape_html_entities_in_json = false

    respond_to do |format|
      format.html { render :json => resp.to_json }
      format.json { render :json => resp.to_json }
      format.xml  { render :xml => resp.to_xml(:root => "oembed") }
    end 

    ActiveSupport.escape_html_entities_in_json = true
  
  end



end