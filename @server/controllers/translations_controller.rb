
class TranslationsController < ApplicationController
  respond_to :json


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
    exclude = {'authenticity_token' => 1, 'subdomain' => 1, 'action' => 1, 'controller' => 1}
    updated = params.select{|k,v| !exclude.has_key?(k)}

    if permit('update all translations') > 0
      ActiveRecord::Base.connection.execute("UPDATE datastore SET v='#{JSON.dump(updated)}' WHERE k='#{key}'")
    else 

      translations_made = false

      # allow non super admins to:
      #    - create a translatable message if that message is not yet populating the datastore
      #    - propose new translations to existing translatable messages (only one per user per message)

      old = ActiveRecord::Base.connection.execute("SELECT v FROM datastore WHERE k='#{key}'").to_a()[0]
      old = Oj.load(old[0] || '{}')

      updated.each do |id, message|
        if id == 'key'
          next 
        end

        # Check if this message is present; if not, allow it to be added. 
        # If it is en, add it as default text, otherwise add it as a proposal.
        if !old.has_key?(id)
          if !key.end_with?('/en')
            if message[:txt]
              message = {
                proposals: [{txt: message.txt, u: "/user/#{current_user.id}"}]
              }
            elsif message[:proposals]
              message[:proposals] = [message[:proposals][0]] # only one proposal per user per message
            else 
              next # no txt and no proposals?
            end 
            translations_made = true
          end 

          old[id] = message 

        elsif message[:proposals]
          # should only be allowed to add or replace their own proposal
          old_proposals = old[id][:proposals] || []
          new_proposal = nil 
          message[:proposals].each do |proposal|
            if proposal[:u] == "/user/#{current_user.id}"
              new_proposal = proposal 
              break 
            end 
          end 

          if new_proposal
            translations_made = true
            old_proposal = nil
            old_proposals.each do |proposal|
              if proposal.u == "/user/#{current_user.id}"
                old_proposal = proposal 
              end 
            end 
            if old_proposal
              old_proposal.txt = new_proposal.txt 
            else 
              old_proposals.push new_proposal
            end 

            old[id][:proposals] = old_proposals

          end

        end
      end

      ActiveRecord::Base.connection.execute("UPDATE datastore SET v='#{JSON.dump(old)}' WHERE k='#{key}'")
      if translations_made
        # TODO: test this email function
        EventMailer.translations_proposed(current_subdomain).deliver_later
      end
 
    end

    dirty_key key
    render :json => {:success => true}
  end


end