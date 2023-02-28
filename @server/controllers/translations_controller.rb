
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

    proposals.each do |proposal|
      string_id = proposal['string_id']
      lang_code = proposal['lang_code']
      subdomain = proposal['subdomain_id'] ? Subdomain.find(proposal['subdomain_id'].to_i) : nil
      region = proposal.fetch 'origin_server', APP_CONFIG[:region]
      translation = proposal['translation']

      existing = Translations::Translation.where(:string_id => string_id, :lang_code => lang_code, :subdomain_id => subdomain ? subdomain.id : nil)
      accepted = existing.where(:accepted => true).first

      next if (accepted && accepted.translation == translation) || (!translation || translation.length == 0)

      # super admins can always directly update translations
      # allow non super admins to:
      #    - create a translatable message if that message is not yet populating the database
      #    - propose new translations to existing translatable messages (only one per user per message)

      if lang_code == "en" 
        trans = Translations::Translation.create_or_update_native_translation string_id, translation, {:subdomain => subdomain, :region => region}
        if trans && !subdomain
          native_updates.push trans
        end
      else 
        trans = Translations::Translation.create_or_update_proposed_translation lang_code, string_id, translation, {:subdomain => subdomain, :region => region, :accepted_elsewhere => proposal['accepted']}
        if trans && !subdomain
          other_updates.push trans
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

    if other_updates.length > 0 && !params.has_key?('considerit_API_key')
      EventMailer.translations_proposed(subdomain || current_subdomain, other_updates).deliver_later
    end 

    # propagate translation updates to other servers
    params = {
      'proposals' => JSON.dump(proposals),
    }
    push_to_peers "translations.json", params, 'PUT'       

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
    params = {
      'string_id' => params["string_id"]          
    }
    push_to_peers "translations.json", params, 'DELETE'    

    render :json => {:success => true}
  end

  def reject_proposal
    return if Permissions.permit('update all translations') <= 0 && !valid_API_call

    string_id = params["string_id"]
    proposal = JSON.parse(params["proposal"])

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
        params = {
          'proposal' => params["proposal"],
          'string_id' => params["string_id"]          
        }
        push_to_peers "translation_proposal.json", params, 'DELETE'
      end
    end 

    render :json => {:success => true}

  end

  def push_to_peers(endpoint, params, http_method)
    return if params['considerit_API_key'] || !APP_CONFIG[:peers]

    APP_CONFIG[:peers].each do |peer|
      begin 
        Rails.logger.info "Replaying #{http_method} #{endpoint} on Peer #{peer}"
        params['considerit_API_key'] = APP_CONFIG[:considerit_API_key]
        if peer.count(':') > 1 || peer.index('ngrok') # a non-production peer
          params['domain'] = current_subdomain.name
        end

        if http_method == 'PUT'
          response = Excon.put(
            "#{peer}/#{endpoint}", 
            query: params
          )          
        elsif http_method == 'DELETE'
          response = Excon.delete(
            "#{peer}/#{endpoint}", 
            query: params
          )
        else 
          raise "Unsupported method #{http_method} for pushing to peers"
        end 


        Rails.logger.info response
      rescue => err
        ExceptionNotifier.notify_exception err
      end
    end    
  end

  def log_translation_counts
    counts = params["counts"]
    Translations::Translation.log_translation_count JSON.parse(counts).keys
    render :json => {:success => true}
  end

end 







