DEVELOPMENT_LANGUAGE = 'en'
require 'message_format'

###########################
# Translations for server. 
# Mirror of translations.coffee for the client.



# A bit of an anti-pattern, but allow the programmer to
# set the current use and subdomain. This is useful for 
# not requiring the programmer to explicitly pass in 
# user and subdomain with each call to translator, 
# useful especially for email runners running offline.
# Intended to be used with the mailers.  
# Use with caution. 
@translator_user = nil 
@translator_subdomain = nil

def set_translation_context(user, subdomain)
  @translator_user = user 
  @translator_subdomain = subdomain
end

def clear_translation_context
  @translator_user = nil 
  @translator_subdomain = nil
end    


def translator(args, native_text = nil)
  if args.is_a? String
    native_text = args
    args = {}
  end 
  id = args[:id] || native_text

  user = args[:user] || @translator_user || current_user
  subdomain = args[:subdomain] || @translator_subdomain || current_subdomain

  translations_key_prefix = args[:key] || '/translations'

  native_key = "#{translations_key_prefix}/#{DEVELOPMENT_LANGUAGE}"

  translations_native = ActiveRecord::Base.connection.execute("SELECT v FROM datastore WHERE k='#{native_key}'").to_a()[0]
  translations_native = Oj.load(translations_native[0] || "{key: #{native_key}}")

  # make sure default message is in database
  if !translations_native[id] || translations_native[id]["txt"] != native_text
    translations_native[id] ||= {}
    translations_native[id]["txt"] = native_text
    ActiveRecord::Base.connection.execute("UPDATE datastore SET v='#{JSON.dump(translations_native)}' WHERE k='#{native_key}'")
  end 

  # which language should we use? ordered by preference. 
  langs = [user[:lang], subdomain[:lang], DEVELOPMENT_LANGUAGE].uniq

  # find the best language translation we have
  lang_used = nil 
  message = nil 
  langs.each do |lang| 
    next if !lang 

    lang_key = "#{translations_key_prefix}/#{lang}"
    lang_trans = ActiveRecord::Base.connection.execute("SELECT v FROM datastore WHERE k='#{lang_key}'").to_a()[0]
    lang_trans = Oj.load(lang_trans[0] || "{key: #{lang_key}}")

    if lang_trans[id] && lang_trans[id]["txt"]
      message = lang_trans[id]["txt"]
      lang_used = lang
      break 
    end 
  end

  if message 
    mf = MessageFormat.new(message, lang_used)
    message = mf.format(args)
  else 
    message = native_text
  end

  message


end


# made for translating emails where there might be snippets of html

def translator_html(native_text, args = nil)
  message = translator args, native_text

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