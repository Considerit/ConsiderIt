class DirectMessageController < ApplicationController
  respond_to :json

  def create
    attrs = {
      'recipient' => key_id(params['recipient']),
      'body' => params['body'],
      'subject' => params['subject'],
      'sender' => params['sender']
    }
    @message = DirectMessage.new(attrs)

    if @message.valid?
      EventMailer.send_message(@message, current_user, mail_options()).deliver
      render :json => {:result => 'success'}

    else
      render :json => {:result => 'failure'}
    end
  end

end