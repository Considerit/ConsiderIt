class Dashboard::MessageController < ApplicationController
  respond_to :json

  def create
    if params.has_key? :message
      @message = Message.new(params[:message])
    else
      attrs = {
        'recipient' => key_id(params['recipient']),
        'body' => params['body'],
        'subject' => params['subject'],
        'sender' => params['sender']
      }
      @message = Message.new(attrs)
    end    

    if @message.valid?
      EventMailer.send_message(@message, current_user, mail_options()).deliver
      render :json => {:result => 'success'}

    else
      render :json => {:result => 'failure'}
    end
  end

end