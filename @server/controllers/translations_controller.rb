
class TranslationsController < ApplicationController

  include Translations::PSEUDOLOCALIZATION


  def show 
    if params.has_key? :subdomain
      key = "/translations/#{params[:subdomain]}"
    else 
      key = "/translations"
    end 

    dirty_key key
    render :json => []
  end


  def update


    key = params[:key]


    if !key.start_with?('/translations')
      return
    end 
    
    exclude = {'authenticity_token' => 1, 'subdomain' => 1, 'action' => 1, 'controller' => 1, 'translation' => 1}
    updated = params.select{|k,v| !exclude.has_key?(k)}.to_h

    if Permissions.permit('update all translations') > 0
      Translations.UpdateTranslations(key, updated)
    else 
      translations_made = false

      # allow non super admins to:
      #    - create a translatable message if that message is not yet populating the datastore
      #    - propose new translations to existing translatable messages (only one per user per message)

      old = Translations.GetTranslations(key)

      updated.each do |id, message|
        if id == 'key'
          next 
        end

        if id == 'engage.slider_label.Agree'
          begin
            raise "Translator got a sneaky, old translation string"
          rescue => e
            if current_subdomain
              sub = current_subdomain.name
            else 
              sub = nil
            end 
            ExceptionNotifier.notify_exception(e, data: {request: request, params: params, subdomain: sub})
          end
        end


        # Check if this message is present; if not, allow it to be added. 
        # If it is en, add it as default text, otherwise add it as a proposal.
        if !old.has_key?(id)
          if !key.end_with?('/en')
            txt = message[:txt] || message["txt"]
            if txt
              message = {}
              message["proposals"] = [{"txt": txt, u: "/user/#{current_user.id}"}]
              
            elsif message["proposals"]
              message["proposals"] = [message["proposals"][0]] # only one proposal per user per message
            else 
              next # no txt and no proposals?
            end 
            translations_made = true
          end 

          old[id] = message 

        elsif message["proposals"]


          # should only be allowed to add or replace their own proposal
          old_proposals = old[id]["proposals"] || []
          new_proposal = nil 
          message["proposals"].each do |proposal|
            if proposal["u"] == "/user/#{current_user.id}"
              new_proposal = proposal 
              break 
            end 
          end 

          # # if it comes from the client not as a proposal, then turn it into one...
          # if new_proposal && message["txt"] && new_proposal["txt"] != message["txt"]
          #   new_proposal = {}
          #   new_proposal["txt"] = message["txt"]
          #   new_proposal["u"] = "/user/#{current_user.id}"
          # end 

          if new_proposal
            translations_made = true
            old_proposal = nil
            old_proposals.each do |proposal|
              if proposal["u"] == "/user/#{current_user.id}"
                old_proposal = proposal 
              end 
            end 
            if old_proposal
              old_proposal["txt"] = new_proposal["txt"]
            else 
              old_proposals.push new_proposal
            end 

            old[id]["proposals"] = old_proposals

          end

        end
      end

      Translations.UpdateTranslations(key, old)

      if translations_made
        EventMailer.translations_proposed(current_subdomain).deliver_later
      end
 
    end

    if key.end_with?('/en')
      Translations::PSEUDOLOCALIZATION::synchronize(key)
    end

    dirty_key key
    render :json => {:success => true}
  end

end 







