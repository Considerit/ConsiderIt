class TranslationsLanguagesController < ApplicationController

  def show
    dirty_key '/supported_languages'
    render :json => []
  end

  def update
    return if Permissions.permit('update all translations') <= 0

    currently_supported = Translations::SupportedLanguage.get_all[:available_languages]

    available = params["available_languages"]
    available.each do |lang, name|
      if !currently_supported.has_key?(lang)
        attrs = {
          :lang_code => lang,
          :name => name
        }
        Translations::SupportedLanguage.create! attrs
      end
    end 

    Rails.cache.delete(:supported_languages)
    dirty_key '/supported_languages'
    render :json => []
  end


end