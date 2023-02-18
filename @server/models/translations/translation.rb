DEVELOPMENT_LANGUAGE = 'en'
require 'message_format'


###########################
# Translations for server. 
# Mirror of translations.coffee for the client.


# A bit of an anti-pattern, but allow the programmer to
# set the current user and subdomain. This is useful for 
# not requiring the programmer to explicitly pass in 
# user and subdomain with each call to translator, 
# useful especially for email runners running offline.
# Intended to be used with the mailers.  
# Use with caution. 
@translator_user = nil 
@translator_subdomain = nil

class Translations::Translation < ApplicationRecord
  
  self.table_name = "language_translations"


  def self.get(args, native_text = nil)
    if args.is_a? String
      if !native_text 
        native_text = args
        args = {}
      else
        id = args
        args = {id: id}
      end 
    end 

    id = args[:id] || native_text

    subdomain = args[:subdomain] || @translator_subdomain || current_subdomain

    translations_key_prefix = args[:key] || '/translations'

    # todo: just have a namespace or domain param instead of /translations/domain/id
    use_subdomain = translations_key_prefix.split('/').length == 4


    translations_native = Translations::Translation.translations_for(DEVELOPMENT_LANGUAGE, use_subdomain ? subdomain : nil) 


    # make sure default message is in database
    if !translations_native[id] || translations_native[id] != native_text
      self.create_or_update_native_translation id, native_text, use_subdomain ? subdomain : nil
    end 


    # which language should we use? ordered by preference. 
    user = args[:user] || @translator_user || current_user
    begin 
      if !subdomain 
        langs = [DEVELOPMENT_LANGUAGE]
      elsif user 
        langs = [user[:lang], subdomain[:lang], DEVELOPMENT_LANGUAGE].uniq
      else 
        langs = [subdomain[:lang], DEVELOPMENT_LANGUAGE].uniq
      end
    rescue
      raise "Could not get langs for translating for email: user #{user} subdomain #{subdomain} args #{args}"
    end 
    # find the best language translation we have
    lang_used = nil 
    message = nil 
    langs.each do |lang| 
      next if !lang 

      lang_trans = self.translations_for(lang, use_subdomain ? subdomain : nil) 


      if lang_trans[id]
        message = lang_trans[id]
        lang_used = lang
        break 
      end 
    end


    if message 
      begin
        mf = MessageFormat.new(message, lang_used)
        message = mf.format(args)
      rescue => e
        pp 'translator', e
        ExceptionNotifier.notify_exception(e)
        message = native_text
      end
      
    else 
      message = native_text
    end

    message
  end

  # made for translating emails where there might be snippets of html

  def self.getForHTML(args, native_text)
    if args.is_a? String
      native_text = args
      args = {}
    end 

    message = self.get args, native_text

    # convert any <link> references
    # ...respecting text & html output

    if message.index('<')
      parts = message.split /<(\w+)>[^<]+<\/[\w|\s]+>/
      matches = {}
      message.scan(/<(\w+)>([^<]+)<\/[\w|\s]+>/).each do |match|
        matches[match[0]] = match[1]
      end 

      translation = []
      parts.each do |part|
        if matches.has_key?(part) && args.has_key?(part.to_sym)
          definition = args[part.to_sym]
          attrs = ""
          definition[:attrs].each do |attr, val|
            attrs += " #{attr}=\"#{val}\""
          end
          translation.push "<#{definition[:tag]} #{attrs}>#{matches[part]}</#{definition[:tag]}>"
        else 
          translation.push part 
        end
      end 
      message = translation.join

    end 

    message

  end

  def self.SetTranslationContext(user, subdomain)
    @translator_user = user 
    @translator_subdomain = subdomain

    user = @translator_user || current_user
    subdomain = @translator_subdomain || current_subdomain
    langs = [user[:lang], subdomain[:lang], DEVELOPMENT_LANGUAGE].compact.uniq

    @translation_lang = langs[0]

  end

  def self.ClearTranslationContext
    @translator_user = nil 
    @translator_subdomain = nil
  end    




  def promote

    # demote any other translations for this string
    competing_translation = Translations::Translation.where(:lang => self.lang_code, :string_id => self.string_id, :subdomain_id => self.subdomain_id, :accepted => true)
    
    if competing_translation.count > 1
      raise "Error, multiple accepted translations for #{self.lang_code} #{self.subdomain_id} #{self.string_id}"
    end

    if competing_translation.first.id != self.id
      competing_translation.first.accepted = false
      competing_translation.save 
    end


    self.accepted = true
    self.accepted_at = DateTime.now
    save
  end

  def self.translations_for(lang, subdomain = nil)
    key = translations_key lang, subdomain
    Rails.cache.fetch(key) do
      if subdomain
        key = "/translations/#{subdomain.name}/#{lang}"      

        translations = sanitize_and_execute_query("""
          SELECT string_id, translation FROM language_translations WHERE 
            accepted=true AND lang_code='#{lang}' AND subdomain_id=#{subdomain.id};
        """)
      else 
        translations = sanitize_and_execute_query("""
          SELECT string_id, translation FROM language_translations WHERE 
            accepted=true AND lang_code='#{lang}';
        """)
      end

      all_tr = {
        key: key
      }    

      translations.each do |tr|
        all_tr[tr[0]] = tr[1]
      end

      all_tr
    end
  end

  def self.create_or_update_native_translation(string_id, translation, subdomain = nil)

    trans = nil
    key = nil 

    # This loop might be a bit too cute. Basically, we want to maintain the synchronization
    # between en and pseudo en. We're mainly concerned with adding en. But because we want 
    # the trans and key variables to be set to the value for en, we update pseudo-en first.
    ['pseudo-en', 'en'].each do |lang|
      tr = Translations::Translation.where(:string_id => string_id, :lang_code => lang)
      if subdomain 
        tr = tr.where(:subdomain_id => subdomain.id)
      end
      my_translation = lang == 'en' ? translation : pseudoize_string(translation)
      if tr.count == 0 
        attrs = {
          lang_code: lang,
          string_id: string_id,
          translation: my_translation, 
          subdomain_id: subdomain ? subdomain.id : nil,
          origin_server: APP_CONFIG[:region],
          accepted: true, 
          accepted_at: DateTime.now,
          user_id: current_user.id
        }

        trans = Translations::Translation.create! attrs
      else 
        trans = tr.first
        trans.translation = my_translation
        trans.user_id = current_user.id
        trans.save
      end

      key = translations_key lang, subdomain
      Rails.cache.delete(key)

    end 

    dirty_key key
    trans
  end


  def self.create_or_update_proposed_transation(lang, string_id, translation, subdomain = nil)

    tr = Translations::Translation.where(:string_id => string_id, :lang_code => lang)
    if subdomain 
      tr = tr.where(:subdomain_id => subdomain.id)
    end

    trans = tr.where(:user_id => current_user.id)

    return nil if trans.translation == translation # already proposed

    if !trans
      attrs = {
        lang_code: lang,
        string_id: string_id,
        translation: translation, 
        subdomain_id: subdomain ? subdomain.id : nil,
        origin_server: APP_CONFIG[:region],
        accepted: false, 
        user_id: current_user.id
      }
      trans = Translations::Translation.create! attrs
    else 
      trans.translation = translation
    end

    accepted = tr.where(:accepted => true)
    if accepted.count > 1
      raise "Error, multiple accepted translations for #{lang} #{subdomain ? subdomain.id : ''} #{string_id}"
    end
    accepted = accepted.first

    if Permissions.permit('update all translations') > 0
      trans.promote
    end

    trans.save

    key = translations_key lang, subdomain
    Rails.cache.delete(key)
    dirty_key key
    trans
  end

  def self.translations_key(lang, subdomain=nil)
    "/translations/#{subdomain ? "#{subdomain.name}/" : ""}#{lang}"
  end


  # TODO: copy over translation counts
  # Note: In Rails 5, by passing touch: false as an option to save, we can update the 
  # object without updating timestamps. The default option for touch is true.
  def self.write_translation_counts

  end






  ##########################
  # PSEUDOLOCALIZATION
  # The below is modified from 
  # https://github.com/Shopify/pseudolocalization/blob/master/lib/pseudolocalization/pseudolocalizer.rb

  def self.pseudoize_string(string)
    return "*!#{string}!*" if string.match('plural')

    string.split(ESCAPED_REGEX).map do |part|
      if part =~ ESCAPED_REGEX
        part
      else
        part.chars.map do |char|
          if LETTERS.key?(char)
            value = LETTERS[char]
            value = value * 2 if VOWELS.include?(char)
            value
          else
            char
          end
        end.join
      end
    end.join
  end

  ESCAPED_REGEX = Regexp.new("(#{
    [
      "<.*?>",
      "{.*?}",
      "https?:\/\/\\S+",
      "&\\S*?;"
    ].join('|')
  })")

  VOWELS = %w(a e i o u y A E I O U Y)

  LETTERS = {
    'a' => 'α',
    'b' => 'ḅ',
    'c' => 'ͼ',
    'd' => 'ḍ',
    'e' => 'ḛ',
    'f' => 'ϝ',
    'g' => 'ḡ',
    'h' => 'ḥ',
    'i' => 'ḭ',
    'j' => 'ĵ',
    'k' => 'ḳ',
    'l' => 'ḽ',
    'm' => 'ṃ',
    'n' => 'ṇ',
    'o' => 'ṓ',
    'p' => 'ṗ',
    'q' => 'ʠ',
    'r' => 'ṛ',
    's' => 'ṡ',
    't' => 'ṭ',
    'u' => 'ṵ',
    'v' => 'ṽ',
    'w' => 'ẁ',
    'x' => 'ẋ',
    'y' => 'ẏ',
    'z' => 'ẓ',
    'A' => 'Ḁ',
    'B' => 'Ḃ',
    'C' => 'Ḉ',
    'D' => 'Ḍ',
    'E' => 'Ḛ',
    'F' => 'Ḟ',
    'G' => 'Ḡ',
    'H' => 'Ḥ',
    'I' => 'Ḭ',
    'J' => 'Ĵ',
    'K' => 'Ḱ',
    'L' => 'Ḻ',
    'M' => 'Ṁ',
    'N' => 'Ṅ',
    'O' => 'Ṏ',
    'P' => 'Ṕ',
    'Q' => 'Ǫ',
    'R' => 'Ṛ',
    'S' => 'Ṣ',
    'T' => 'Ṫ',
    'U' => 'Ṳ',
    'V' => 'Ṿ',
    'W' => 'Ŵ',
    'X' => 'Ẋ',
    'Y' => 'Ŷ',
    'Z' => 'Ż',
  }.freeze


end