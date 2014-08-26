class Dashboard::MessageController < ApplicationController
  respond_to :json

  def create
    @message = Message.new(params[:message])
    
    if @message.valid?
      EventMailer.send_message(@message, current_user, mail_options()).deliver
      render :json => {:result => 'success'}

    else
      render :json => {:result => 'failure'}
    end
  end

end