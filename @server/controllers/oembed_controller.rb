require 'cgi'

class OembedController < ApplicationController
  respond_to :html
  
  def show

    width = maxwidth = params[:maxwidth] or 600
    height = maxheight = params[:maxheight] or 400

    format = params[:format] or 'json'  # need to support xml too

    url = CGI.unescape params[:url]
    # pp /\/\/[\d\w.]+\/([\d\w]+)/.match(url)
    # pp /\/\/[\d\w.]+\/([\d\w]+)/.match(url)[1]
    slug = /\/\/[\d\w.]+\/([\d\w\-_]+)/.match(url)[1]
    proposal = Proposal.find_by_slug slug

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
      :html => """<iframe> 
          Hello world!
      </iframe>
      """
    }

    @oembed_request = true


    ActiveSupport.escape_html_entities_in_json = false

    respond_to do |format|
      format.html { render :json => resp.to_json }
      format.json { render :json => resp.to_json }
      format.xml  { render :xml => resp }
    end 

    ActiveSupport.escape_html_entities_in_json = true
  
  end


  # # GET /oembed?url=... json by default
  # # GET /oembed.json?url=...
  # # GET /oembed.json?url=...&callback=myCallback
  # # GET /oembed.xml?url=...
  # def endpoint
  #   # get object that we want an oembed_response from
  #   # based on url
  #   # and get its oembed_response



  #   begin
  #     media_item = ::OembedProviderEngine::OembedProvider.find_provided_from(params[:url])
  #     options = Hash.new
  #     max_dimensions = [:maxwidth, :maxheight]
  #     unless media_item.class::OembedResponse.providable_oembed_type == :link
  #       max_dimensions.each { |dimension| options[dimension] = params[dimension] if params[dimension].present? }
  #     end

  #     @oembed_response = media_item.oembed_response(options)
  #   rescue Exception => e
  #   end

  #   # to_xml and to_json overidden in oembed_providable module
  #   # to be properly formatted
  #   # TODO: handle unauthorized case
  #   respond_to do |format|
  #     if @oembed_response
  #       format.html { render_json @oembed_response.to_json } # return json for default
  #       format.json { render_json @oembed_response.to_json }
  #       format.xml  { render :xml => @oembed_response }
  #     else
  #       format.all { head :not_found }
  #     end
  #   end
  # end

  # protected
  # # thanks to http://blogs.sitepoint.com/2006/10/05/json-p-output-with-rails/
  # def render_json(json, options={})
  #   callback, variable = params[:callback], params[:variable]
  #   response = begin
  #                if callback && variable
  #                  "var #{variable} = #{json};\n#{callback}(#{variable});"
  #                elsif variable
  #                  "var #{variable} = #{json};"
  #                elsif callback
  #                  "#{callback}(#{json});"
  #                else
  #                  json
  #                end
  #              end
  #   render({:content_type => "application/json", :text => response}.merge(options))
  # end


end