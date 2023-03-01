class Translations::SupportedLanguage < ApplicationRecord
  self.table_name = "languages_supported"

  def self.get_all
    Rails.cache.fetch(:supported_languages) do 

      langs = Translations::SupportedLanguage.all

      if langs.count == 0 
        # initialize
        [["en", "English"], ["pseudo-en", "pseudo-english"]].each do |l|
          attrs = {
            lang_code: l[0],
            name: l[1]
          }
          Translations::SupportedLanguage.create! attrs
        end 

        langs = Translations::SupportedLanguage.all
      end


      available = {
        "key": "/supported_languages",
        "available_languages": {}
      }

      langs.each do |lang|
        available[:available_languages][lang.lang_code] = lang.name
      end

      available

    end
  end

end