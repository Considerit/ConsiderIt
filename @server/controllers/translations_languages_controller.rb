class TranslationsLanguagesController < ApplicationController

  def show
    dirty_key '/supported_languages'
    render :json => []
  end

  def update

  end


end