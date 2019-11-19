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

  user = @translator_user || current_user
  subdomain = @translator_subdomain || current_subdomain
  langs = [user[:lang], subdomain[:lang], DEVELOPMENT_LANGUAGE].compact.uniq

  @translation_lang = langs[0]

end

def clear_translation_context
  @translator_user = nil 
  @translator_subdomain = nil
end    


def get_translations(k)
  trans = ActiveRecord::Base.connection.execute("SELECT v FROM datastore WHERE k='#{k}'").to_a()[0]
  if !trans 
    insert_to_translations(k, {key: k})
    trans = ActiveRecord::Base.connection.execute("SELECT v FROM datastore WHERE k='#{k}'").to_a()[0]
  end
  trans = trans[0].gsub("''", "'")
  Oj.load(trans)
end 

def update_translations(k,v)
  escaped = JSON.dump(v).gsub("'", "''")  
  ActiveRecord::Base.connection.execute("UPDATE datastore SET v='#{escaped}' WHERE k='#{k}'")
end

def insert_to_translations(k,v)
  escaped = JSON.dump(v).gsub("'", "''")
  ActiveRecord::Base.connection.execute("INSERT into datastore(k,v) VALUES ('#{k}', '#{escaped}')")
end

def translator(args, native_text = nil)
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

  user = args[:user] || @translator_user || current_user
  subdomain = args[:subdomain] || @translator_subdomain || current_subdomain

  translations_key_prefix = args[:key] || '/translations'

  native_key = "#{translations_key_prefix}/#{DEVELOPMENT_LANGUAGE}"

  translations_native = get_translations(native_key)

  # make sure default message is in database
  if !translations_native[id] || translations_native[id]["txt"] != native_text
    translations_native[id] ||= {}
    translations_native[id]["txt"] = native_text
    update_translations(native_key, translations_native)
    PSEUDOLOCALIZATION::synchronize(native_key)
  end 

  # which language should we use? ordered by preference. 
  langs = [user[:lang], subdomain[:lang], DEVELOPMENT_LANGUAGE].uniq

  # find the best language translation we have
  lang_used = nil 
  message = nil 
  langs.each do |lang| 
    next if !lang 

    lang_key = "#{translations_key_prefix}/#{lang}"
    lang_trans = get_translations(lang_key)

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

def translator_html(args, native_text)
  if args.is_a? String
    native_text = args
    args = {}
  end 

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


module PSEUDOLOCALIZATION

  def self.synchronize(key)
    # make sure that pseudolocalization version of each default string is present
    prefix = key.split('/en')[0]
    ps_key = prefix + '/pseudo-en'
    en = get_translations("#{prefix}/en")
    ps = get_translations(ps_key)
    if !ps 
      ps = {key: ps_key}
      insert_to_translations(ps_key, ps)
    end

    dirty = false
    en.each do |k,v|
      next if k == 'key'
      next if !v["txt"]

      trans = translate_string(v["txt"])

      ps[k] ||= {txt: ''}
      if ps[k][:txt] != trans 
        ps[k][:txt] = trans
        dirty = true
      end
    end
    if dirty 
      update_translations(ps_key, ps)
    end

  end


  ##########################
  # The below is modified from 
  # https://github.com/Shopify/pseudolocalization/blob/master/lib/pseudolocalization/pseudolocalizer.rb



  def self.translate_string(string)
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
