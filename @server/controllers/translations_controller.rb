
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

    if permit('update all translations') > 0 && params[:lang]
      fields = ['key', 'lang', 'development_language']
      updates = params.select{|k,v| fields.include? k}
      ActiveRecord::Base.connection.execute("UPDATE datastore SET v='#{JSON.dump(updates)}' WHERE k='#{key}'")
    end

    dirty_key key
    render :json => {:success => true}
  end


end