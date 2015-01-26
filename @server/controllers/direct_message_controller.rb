class DirectMessageController < ApplicationController
  respond_to :json

  def create
    fields = ['recipient', 'body', 'subject', 'sender_mask']
    message = params.select{|k,v| fields.include?(k) && v.length > 0}

    if message.keys().length == fields.length # validate presence
      EventMailer.send_message(message, current_user, current_subdomain).deliver_later
      render :json => {:result => 'success'}
    else
      render :json => {:result => 'failure'}
    end
  end

end