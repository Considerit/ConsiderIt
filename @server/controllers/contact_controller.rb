class ContactController < ApplicationController
  respond_to :json

  def create

    ignore = ['key', 'inquiry', 'authenticity_token', 'controller', 'action']
    fields = params.select{|k,v| !ignore.include?(k)}

    inquiry = params['inquiry']

    subj = "[contact] #{inquiry}"
    msg = ""
    fields.each do |field|
      msg += "--------------------------\n#{field[0].gsub('-', ' ')}\n--------------------------\n#{field[1]}\n\n"
    end

    # First, instantiate the Mailgun Client with your API key
    mg_client = Mailgun::Client.new

    # Define your message parameters
    message_params =  { from: '"Considerit Contact Form"<homepage@mg.consider.it>',
                        to:   'hello@consider.it',
                        subject: subj,
                        text:    msg
                      }

    # Send your message through the client
    mg_client.send_message 'mg.consider.it', message_params

    original_id = key_id(params[:key])

    render :json => { 
      :success => true, 
      :errors => [],
      :subject => subj, 
      :body => msg, 
      :key => "/contact_us/#{original_id}?original_id=#{original_id}"  
    }
  end

end
