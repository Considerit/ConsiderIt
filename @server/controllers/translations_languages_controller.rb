class TranslationsLanguagesController < ApplicationController

  def show
    dirty_key '/supported_languages'
    render :json => []
  end

  def update
    return if !params['considerit_API_key'] && Permissions.permit('update all translations') <= 0

    currently_supported = Translations::SupportedLanguage.get_all[:available_languages]

    added_new = false
    available = params["available_languages"]
    available.each do |lang, name|
      if !currently_supported.has_key?(lang)
        attrs = {
          :lang_code => lang,
          :name => name
        }
        Translations::SupportedLanguage.create! attrs
        added_new = true
      end
    end 

    if added_new
      query = {
          "available_languages" => JSON.dump(params["available_languages"])
      }
      push_to_peers("supported_languages.json", query, 'PUT')  
    end

    Rails.cache.delete(:supported_languages)
    dirty_key '/supported_languages'
    render :json => []
  end



  def push_to_peers(endpoint, query_params, http_method)
    return if params['considerit_API_key'] || !APP_CONFIG[:peers]

    APP_CONFIG[:peers].each do |peer|
      begin 
        Rails.logger.info "***************"
        Rails.logger.info "Replaying #{http_method} #{endpoint} on Peer #{peer}"
        query_params['considerit_API_key'] = APP_CONFIG[:considerit_API_key]
        if peer.count(':') > 1 || peer.index('ngrok') # a non-production peer
          query_params['domain'] = current_subdomain.name
        end

        if http_method == 'PUT'
          response = Excon.put(
            "#{peer}/#{endpoint}", 
            query: query_params
          )          
        elsif http_method == 'DELETE'
          response = Excon.delete(
            "#{peer}/#{endpoint}", 
            query: query_params
          )
        else 
          raise "Unsupported method #{http_method} for pushing to peers"
        end 

        if response.status != 200
          Rails.logger.info "Failed to replay transactions to #{peer}."
          Rails.logger.info "#{response.body}"
        end
        Rails.logger.info "***************"


      rescue => err
        ExceptionNotifier.notify_exception err, data: {peer: peer}
      end
    end    
  end



end