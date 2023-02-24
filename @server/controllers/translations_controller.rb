
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

    if current_user.registered || valid_API_call

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
        #    - create a translatable message if that message is not yet populating the datastore
        #    - propose new translations to existing translatable messages (only one per user per message)

        if lang_code == "en" 
          trans = Translations::Translation.create_or_update_native_translation string_id, translation, {:subdomain => subdomain, :region => region}
          native_updates.push trans
        else 
          trans = Translations::Translation.create_or_update_proposed_translation lang_code, string_id, translation, {:subdomain => subdomain, :region => region, :accepted_elsewhere => proposal['accepted']}
          if trans 
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
      if !params['considerit_API_key'] && APP_CONFIG[:peers]
        APP_CONFIG[:peers].each do |peer|
          begin 
            response = Excon.put(
              "#{peer}/translations.json",
              query: {
                'domain' => current_subdomain.name,
                'proposals' => JSON.dump(proposals),
                'considerit_API_key' => APP_CONFIG[:considerit_API_key]
              }
            ) 
          rescue => err
            ExceptionNotifier.notify_exception err

          end
        end      
      end
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

      dirty_key "/translations/#{subdomain ? "#{subdomain.name}/" : ""}#{lang}"
      dirty_key "/proposed_translations/#{lang}#{subdomain ? "/#{subdomain.name}" : ''}"

      str.destroy!
    end

    # propagate string deletion to other servers
    if !params['considerit_API_key'] && APP_CONFIG[:peers]
      APP_CONFIG[:peers].each do |peer|
        begin 
          response = Excon.delete(
            "#{peer}/translations.json",
            query: {
              'domain' => current_subdomain.name,
              'string_id' => params["string_id"],
              'considerit_API_key' => APP_CONFIG[:considerit_API_key]
            }
          ) 
        rescue => err
          ExceptionNotifier.notify_exception err
        end
      end      
    end



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

      dirty_key "/translations/#{to_delete.subdomain_id ? "#{Subdomain.find(to_delete.subdomain_id).name}/" : ""}#{to_delete.lang_code}"
      dirty_key "/proposed_translations/#{to_delete.lang_code}#{to_delete.subdomain_id ? "#{Subdomain.find(to_delete.subdomain_id).name}" : ''}"

      # propagate proposal rejection to other servers
      if !params['considerit_API_key'] && APP_CONFIG[:peers]
        APP_CONFIG[:peers].each do |peer|

          begin 
            response = Excon.delete(
              "#{peer}/translation_proposal.json",
              query: {
                'domain' => current_subdomain.name,
                'proposal' => params["proposal"],
                'string_id' => params["string_id"],
                'considerit_API_key' => APP_CONFIG[:considerit_API_key]
              }
            ) 
          rescue => err
            ExceptionNotifier.notify_exception err

          end
        end      
      end
    end 



    render :json => {:success => true}

  end


  def log_translation_counts
    counts = params["counts"]
    Translations::Translation.log_translation_count JSON.parse(counts).keys
    render :json => {:success => true}
  end

end 







