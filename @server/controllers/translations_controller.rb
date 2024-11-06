
# For testing peer synchronization of translations between servers locally, run:
# rails s -p 3002 -e test --pid tmp/pids/server2.pid
# ...to set up a second server running on local host

class TranslationsController < ApplicationController

  # getting all proposed translations
  def index 
    key = request.path.split(".")[0]

    dirty_key key 

    render :json => []
  end


  def show 
    if !request.path.start_with?('/translations')
      return
    end 

    dirty_key request.path.split(".")[0]
    render :json => []
  end



  # batch update translations
  def update
    proposals = JSON.parse(params[:proposals])

    native_updates = []
    other_updates = []

    subdomain = nil 

    for_peers = []
    proposals.each do |proposal|
      string_id = proposal['string_id']
      lang_code = proposal['lang_code']
      subdomain = proposal['subdomain_id'] ? Subdomain.find(proposal['subdomain_id'].to_i) : nil
      region = proposal.fetch 'origin_server', APP_CONFIG[:region]
      translation = proposal['translation']

      existing = Translations::Translation.where(:string_id => string_id, :lang_code => lang_code, :subdomain_id => subdomain ? subdomain.id : nil)
      accepted = existing.where(:accepted => true).first

      if (accepted && accepted.translation == translation) || (!translation || translation.length == 0)
        for_peers.push proposal # we still want to push it to peers incase they haven't received it yet. 
      end 

      # super admins can always directly update translations
      # allow non super admins to:
      #    - create a translatable message if that message is not yet populating the database
      #    - propose new translations to existing translatable messages (only one per user per message)

      if lang_code == "en" 
        trans = Translations::Translation.create_or_update_native_translation string_id, translation, {:subdomain => subdomain, :region => region}
        if trans && !subdomain
          native_updates.push trans
          for_peers.push proposal
        end
      else 
        trans = Translations::Translation.create_or_update_proposed_translation lang_code, string_id, translation, {:subdomain => subdomain, :region => region, :accepted => proposal['accepted']}
        if trans && !subdomain
          other_updates.push trans
          for_peers.push proposal
        end
      end

      # capture vals for passing along to peer servers
      if !params['considerit_API_key']
        proposal['origin_server'] = APP_CONFIG[:region]
        if trans.accepted
          proposal['accepted'] = true
        end
      end
    end

    if native_updates.length > 0 && !params.has_key?('considerit_API_key')
      EventMailer.translations_native_changed(subdomain || current_subdomain, native_updates).deliver_later
    end 

    if other_updates.length > 0 && !params.has_key?('considerit_API_key') && !current_user.super_admin
      EventMailer.translations_proposed(subdomain || current_subdomain, other_updates).deliver_later
    end 


    ##################
    # Rails.cache.delete_matched "TRANSLATION: "   <--- not supported in MemCacheStore
    # So, instead do this:
    pattern = "TRANSLATION:"
    cache_keys = Rails.cache.instance_variable_get(:@data).try(:keys) || []
    keys_to_delete = cache_keys.select { |key| key.start_with?(pattern) }
    keys_to_delete.each do |key|
      Rails.cache.delete(key)
    end
    ##########

    # propagate translation updates to other servers
    if for_peers.length > 0 
      query = {
        'proposals' => JSON.dump(for_peers),
      }
      push_to_peers "translations.json", query, 'PUT' 
    end       

    render :json => {:success => true}

  end


  # delete all translations of a string
  def delete
    return if Permissions.permit('update all translations') <= 0 && !valid_API_call

    string_id = params["string_id"]

    Translations::Translation.where(:string_id => string_id).each do |str| 
      if str.subdomain_id
        subdomain = Subdomain.find(str.subdomain_id)
      else 
        subdomain = nil
      end
      lang = str.lang_code

      key = Translations::Translation.translations_key lang, subdomain
      dirty_key key
      dirty_key "/proposed_translations/#{lang}#{subdomain ? "/#{subdomain.name}" : ''}"
      Rails.cache.delete(key)


      str.destroy!
    end

    # propagate string deletion to other servers
    query = {
      'string_id' => params["string_id"]          
    }
    push_to_peers "translations.json", query, 'DELETE'    

    render :json => {:success => true}
  end

  def reject_proposal
    return if Permissions.permit('update all translations') <= 0 && !valid_API_call

    proposals = JSON.parse(params["proposals"])

    to_propagate = []

    proposals.each do |proposal|
      string_id = proposal["string_id"]

      to_delete = Translations::Translation.where(:string_id => string_id, :translation => proposal["translation"], :lang_code => proposal["lang_code"], :accepted => false)
      to_delete = to_delete.first

      if to_delete
        to_delete.destroy

        subdomain = to_delete.subdomain_id ? Subdomain.find(to_delete.subdomain_id) : nil
        key = Translations::Translation.translations_key to_delete.lang_code, subdomain
        dirty_key key
        dirty_key "/proposed_translations/#{to_delete.lang_code}#{subdomain ? "/#{subdomain.name}" : ''}"
        Rails.cache.delete(key)

        # propagate proposal rejection to other servers
        if !subdomain
          to_propagate.push proposal
        end
      end 
    end

    if to_propagate.length > 0
      query = {
        'proposals' => JSON.dump(to_propagate)
      }
      push_to_peers "translation_proposal.json", query, 'DELETE'
    end

    render :json => {:success => true}

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

  def log_translation_counts
    counts = params["counts"]
    Translations::Translation.log_translation_count JSON.parse(counts).keys
    query = {
      'counts' => counts
    }
    push_to_peers "log_translation_counts.json", query, 'PUT'
    render :json => {:success => true}
  end

end 







