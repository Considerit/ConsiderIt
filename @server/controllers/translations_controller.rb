
class TranslationsController < ApplicationController

  # getting all proposed translations
  def index 
    key = request.path
    dirty_key key 
    render :json => []
  end


  def show 
    if !request.path.start_with?('/translations')
      return
    end 

    dirty_key request.path
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

      translation = proposal['translation']

      existing = Translations::Translation.where(:string_id => string_id, :lang_code => lang_code, :subdomain_id => subdomain ? subdomain.id : nil)
      accepted = existing.where(:accepted => true).first

      next if (accepted && accepted.translation == translation) || (!translation || translation.length == 0)

      # super admins can always directly update translations
      # allow non super admins to:
      #    - create a translatable message if that message is not yet populating the datastore
      #    - propose new translations to existing translatable messages (only one per user per message)

      if lang_code == "en" 
        trans = Translations::Translation.create_or_update_native_translation string_id, translation, subdomain
        native_updates.push trans
      else 
        trans = Translations::Translation.create_or_update_proposed_transation lang_code, string_id, translation, subdomain
        if trans 
          other_updates.push trans
        end
      end

    end

    if native_updates.length > 0
      EventMailer.translations_native_changed(subdomain || current_subdomain, native_updates).deliver_later
    end 

    if other_updates.length > 0 
      EventMailer.translations_proposed(subdomain || current_subdomain, other_updates).deliver_later
    end 


    render :json => {:success => true}

  end


  # delete all translations of a string
  def delete
    return if Permissions.permit('update all translations') <= 0

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

    render :json => {:success => true}
  end

  def reject_proposal
    return if Permissions.permit('update all translations') <= 0

    string_id = params["string_id"]
    proposal = params["proposal"]

    id = JSON.parse(proposal)["id"]

    to_delete = Translations::Translation.find(id)
    if to_delete
      to_delete.destroy

      dirty_key "/translations/#{to_delete.subdomain_id ? "#{Subdomain.find(to_delete.subdomain_id).name}/" : ""}#{to_delete.lang_code}"
      dirty_key "/proposed_translations/#{to_delete.lang_code}#{to_delete.subdomain_id ? "#{Subdomain.find(to_delete.subdomain_id).name}" : ''}"

    end

    render :json => {:success => true}

  end

end 







