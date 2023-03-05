require '../customizations'


window.translation_progress = (lang, key_prefix) -> 
  key_prefix ||= '/translations'
  proposed_translations = fetch "/proposed_translations/#{lang}#{key_prefix.replace('/translations', '')}"
  dev_language = fetch "#{key_prefix}/en"
  target_lang = fetch "#{key_prefix}/#{lang}"

  translated = (k for k,v of dev_language when target_lang[k] or proposed_translations[k])

  translated.length / (Object.keys(dev_language).length - 1)


regexp_tsplit = /<(\w+)>[^<]+<\/[\w|\s]+>/g
regexp_tmatch = /<(\w+)>([^<]+)<\/[\w|\s]+>/g
window.TRANSLATE = (args, native_text) -> 
  
  if typeof args == "string"
    if native_text
      args = {id: args}
    else 
      native_text = args 
      args = {}

  tr = fetch 'translations'

  args.return_lang_used = true
  if args.key
    console.trace()
    console.warn("args.key is no longer accepted for translator. use local=true instead")
  {message, lang_used, target_lang} = translator args, native_text 

  return native_text if !message
  
  # allow composing of components into translatable messages
  if message.indexOf('<') > -1
    parts = message.split(regexp_tsplit)
    matches = {}


    while match = regexp_tmatch.exec(message)
      matches[match[1]] = match[2]

    translation = []
    for part in parts 
      if part of matches && part of args 
        def = args[part]
        if args.as_html
          translation.push "<#{def.component} #{def.args}>#{matches[part]}</#{def.component}>"
        else 
          translation.push def.component(def.args, matches[part])

      else 
        translation.push part 

  else 
    translation = message

  if !tr.in_situ_translations
    translation 
  else 
    translations = fetch "/translations/#{target_lang}"

    props = _.extend({lang_used, target_lang, message, native_text}, args)
    props.translation_key = props.key
    IN_SITU_TRANSLATOR props, translation



IN_SITU_TRANSLATOR = ReactiveComponent
  displayName: 'InSituTranslator'
  render: ->
    key = @props.translation_key or '/translations'
    target_lang = @props.target_lang

    translated = @props.lang_used == target_lang
    id = @props.id or @props.native_text

    SPAN 
      style: 
        backgroundColor: if translated then "rgba(166, 195, 151, .5)" else "rgba(251,124,124,.5)"
        position: 'relative'
      onMouseOver: =>
        if !@local.show_translator
          @local.show_translator = true 
          save @local

      @props.children

      if @local.show_translator
        available_languages = fetch('/supported_languages').available_languages

        if @props.local 
          subdomain = fetch('/subdomain')
          updated_translations = fetch "local_translations/#{target_lang}/#{subdomain.name}"
          proposed_translations = fetch "/proposed_translations/#{target_lang}/#{subdomain.name}"
          subdomain_id = subdomain.id
        else 
          updated_translations = fetch "local_translations/#{target_lang}"
          proposed_translations = fetch "/proposed_translations/#{target_lang}"
          subdomain_id = null

        message_style = 
          fontWeight: 700

        DIV 
          style: 
            position: 'absolute'
            zIndex: 9999
            fontSize: 14
            width: 300
            padding: '4px 8px'
            backgroundColor: 'white'
            border: "1px solid #ccc"

          onClick: (e) => 
            e.stopPropagation()
            e.preventDefault()

          DIV 
            style: {}
            "English message: "
            DIV 
              style: message_style
              "#{@props.native_text}"

          DIV 
            style: 
              marginTop: 8
            LABEL null, 
              "#{available_languages[target_lang]} translation:"

            editable_translation id, target_lang, subdomain_id, updated_translations, proposed_translations.proposals[id], message_style


          BUTTON 
            className: "btn"
            style: 
              fontSize: 14
            onClick: => 
              promote_temporary_translations(updated_translations.key)
              @local.show_translator = false 
              save @local 

            "Save" 

          BUTTON 
            style: 
              backgroundColor: 'none'
              border: 'none'
              color: '#888'

            onClick: => 
              @local.show_translator = false 
              save @local 
            "Cancel" 

              




DEVELOPMENT_LANGUAGE = 'en'

translation_cache = {}
translations_loaded = false 
window.T = window.t = (args, native_text) ->
  console.trace()
  console.warn "Deprecated: calling window.t or window.T should be replaced with window.translator"
  translator args, native_text





window.translator = (args, native_text) -> 
  # if !native_text
  #   native_text = ""
  #   console.error("Native text for translation is null", args, native_text)

  if translations_loaded 
    cache_key = JSON.stringify(args, native_text)
    if cache_key of translation_cache

      if typeof args == "string"
        if native_text
          args = {id: args}
        else 
          native_text = args 
          args = {}

      id = args.id or native_text
      log_translation_count id
      return translation_cache[cache_key]


  if args.key
    console.trace()
    console.warn("Deprecated: do not pass args.key to translator. Pass in local: true instead")

  subdomain = fetch '/subdomain'
  if args.local && !subdomain.name 
    return '...'

  if args.local
    translations_key_prefix = "/translations/#{subdomain.name}"
  else 
    translations_key_prefix = "/translations"

  translations_native = fetch "#{translations_key_prefix}/#{DEVELOPMENT_LANGUAGE}"
  return '...' if waiting_for(translations_native)

  translations_loaded ||= true
  cache_key ?= JSON.stringify(args, native_text)

  if typeof args == "string"
    if native_text
      args = {id: args}
    else 
      native_text = args 
      args = {}

  id = args.id or native_text

  native_text = native_text.replace(/\n/g, "")


  # ensure this string is in the translations database for the development language
  if translations_native[id] != native_text
    console.log 'updating', {args: args, key: translations_native.key, id, native_text, saved: translations_native[id]}, translations_native[id] == native_text

    translations_native[id] = native_text
    setTimeout ->
      proposed_update =
        string_id: id
        lang_code: DEVELOPMENT_LANGUAGE
        subdomain_id: if args.local then subdomain.id else null
        translation: native_text
      updateTranslations [proposed_update]
    , 1000

  # which language should we use? ordered by preference. 
  # user = fetch '/current_user'
  user = {}
  langs = [user.lang, subdomain.lang, DEVELOPMENT_LANGUAGE].filter((l) -> l?)
  langs = Array.from(new Set(langs)) if langs.length > 1

  # find the best language translation we have
  lang_used = null 
  message = null 
  for lang in langs
    translations = fetch "#{translations_key_prefix}/#{lang}"
    if translations[id]?
      message = translations[id]
      # if this user has proposed one, use that
      # TODO!!!!! Update this
      # if translations[id].proposals?.length > 0
      #   u = fetch('/current_user').user
      #   for proposal in translations[id].proposals
      #     if proposal.u == u 
      #       message = proposal.txt 
      if message
        lang_used = lang 
        break 

  try 
    translator = new IntlMessageFormat.IntlMessageFormat message, lang_used
    message = translator.format(args)
  catch e
     # this is a bad fallback, as plural rules won't work
    console.error "Error translating #{id}", {error: e, message, native_text}
    message = translations_native[id]

  if args.return_lang_used # useful for a T wrapper that enables in situ translations
    translation_cache[cache_key] = {message, lang_used, target_lang: fetch('translations').translating_lang or langs[0]}
  else 
    translation_cache[cache_key] = message

  log_translation_count id

  translation_cache[cache_key] 


translation_uses = {}
translation_uses_write_after = 1000 * 80 
translation_uses_last_written_at = Date.now() - translation_uses_write_after * .75 # first one should be quicker

log_translation_count = (string_id) -> 
  return if window.navigator.userAgent?.indexOf('Prerender') > -1

  translation_uses[string_id] = 1

  if Date.now() - translation_uses_last_written_at >= translation_uses_write_after

    if Object.keys(translation_uses).length > 0 
      frm = new FormData()
      frm.append "authenticity_token", arest.csrf()
      frm.append "counts", JSON.stringify(translation_uses)

      xhr = new XMLHttpRequest
      xhr.addEventListener 'readystatechange', null, false

      xhr.setRequestHeader('Accept','application/json')
      xhr.setRequestHeader("Content-Type", "application/json;charset=UTF-8")
      xhr.setRequestHeader('X-CSRF-Token', arest.csrf())
      xhr.setRequestHeader('X-Requested-With','XMLHttpRequest')

      xhr.open 'PUT', '/log_translation_counts', true
      xhr.send frm

    translation_uses = {}
    translation_uses_last_written_at = Date.now()


styles += """
.translation_filters {
  margin-top: 48px;
}

.translation_filters button {
  background-color: #eaeaea;
  border: none;
  border-radius: 8px;
  margin: 0 8px;
}

.translation_filters button.active {
  background-color: #{focus_blue};
  color: white;
}

"""


TranslationsDash = ReactiveComponent
  displayName: 'TranslationsDash'

  render : ->

    subdomain = fetch '/subdomain'
    current_user = fetch '/current_user'
    translations = fetch '/supported_languages'

    return DIV() if !translations.available_languages

    local = fetch 'translations'
    local.filters ?= []

    all_langs = ( [k,v] for k,v of translations.available_languages when k != DEVELOPMENT_LANGUAGE)
    if current_user.is_super_admin
      all_langs.push ['pseudo-en', "Pseudo English (for testing)"]

    if !local.translating_lang
      if subdomain.lang && subdomain.lang != 'en'
        local.translating_lang = subdomain.lang 
      else 
        local.translating_lang = all_langs[0][0]

    DIV null, 

      DIV style: {},
        "Consider.it's native development language is English (en). Please help us translate it to your language!"

      DIV 
        style: 
          marginTop: 24

        "Which language do you wish to translate for?"


        SELECT 
          value: local.translating_lang or subdomain.lang or 'en'
          style: 
            fontSize: 20
            marginLeft: 14
            display: 'inline-block'
          onChange: (ev) => 
            local.translating_lang = ev.target.value
            save local

          for [k,v] in all_langs
            OPTION 
              key: "#{k}-#{v}"
              value: k
              "#{v} (#{k})"

        DIV 
          style: 
            fontSize: 12
          "Is your language not available? Email us at hello@consider.it to get your language added."


      if current_user.is_super_admin
        DIV 
          style: 
            marginTop: 24

          LABEL 
            htmlFor: 'insitutranslations'
            "Enable in-situ translations?"

          INPUT 
            id: 'insitutranslations'
            type: 'checkbox' 
            checked: fetch('translations').in_situ_translations
            style: 
              fontSize: 36
            onChange: => 
              tr = fetch 'translations'
              tr.in_situ_translations = !tr.in_situ_translations
              save tr 

          DIV 
            style: 
              fontSize: 12
            "In-situ mode lets you browse the rest of the site and add some translations in context."


      if current_user.is_super_admin
        DIV 
          style: 
            marginTop: 24

          "Add a new language"

          DIV null,

            INPUT 
              style: 
                fontSize: 18
              type: 'text'
              ref: 'newlang_abbrev'
              placeholder: 'Abbreviation'

            INPUT               
              type: 'text'
              ref: 'newlang_label'
              placeholder: 'Full Name'
              style: 
                margin: '0 8px'
                fontSize: 18

            BUTTON
              onClick: => 
                abbrev = @refs.newlang_abbrev.value
                label = @refs.newlang_label.value

                if abbrev not of translations.available_languages
                  translations.available_languages[abbrev] = label 
                  save translations

                  @refs.newlang_abbrev.value = ""
                  @refs.newlang_label.value = ""

              "Add"


      if local.translating_lang
        filters = ['Untranslated', 'Not translated by you', 'High use', 'Medium use', 'Low use', 'Rarely used']
        if current_user.is_super_admin
          filters.push 'Under review'

        DIV null, 

          DIV 
            className: 'translation_filters'

            LABEL null,
              "Filter translations to:"

            for filter in filters
              do (filter) => 
                BUTTON
                  key: filter
                  className: if filter in local.filters then 'active'
                  onClick: => 
                    if filter in local.filters
                      local.filters.splice local.filters.indexOf(filter), 1
                    else 
                      local.filters.push filter
                    save local
                  filter


          TranslationsForLang
            key: "translations_for_#{local.translating_lang}"
            lang: local.translating_lang
            filtered_users: local.filters

          TranslationsForLang
            key: "forum_translations_for_#{local.translating_lang}"            
            lang: local.translating_lang
            forum_specific: true
            filters: local.filters


          DIV
            style: 
              position: 'fixed'
              bottom: 0
              left: 0
              width: WINDOW_WIDTH()
              zIndex: 999
              backgroundColor: 'rgba(220,220,220,.8)'
              textAlign: 'center'
              padding: '8px'

            BUTTON 
              className: 'btn'
              onClick: => 
                promote_temporary_translations("local_translations/#{local.translating_lang}")                  
                promote_temporary_translations("local_translations/#{local.translating_lang}/#{subdomain.name}")
              
              "Save Changes"

            if fetch('translations_interface').saved_successfully
              DIV
                style: 
                  color: 'green'
                  marginTop: 10
                "Successfully saved"





TranslationsForLang = ReactiveComponent
  displayName: 'TranslationsForLang'

  render: ->

    lang = @props.lang 
    subdomain = fetch('/subdomain')

    if @props.forum_specific
      translation_key_prefix = "/translations/#{subdomain.name}"
      proposed_translations = fetch "/proposed_translations/#{lang}/#{subdomain.name}"
      subdomain_id = subdomain.id
      updated_translations = fetch "local_translations/#{lang}/#{subdomain.name}"

    else 
      translation_key_prefix = "/translations"
      proposed_translations = fetch "/proposed_translations/#{lang}"
      subdomain_id = null
      updated_translations = fetch "local_translations/#{lang}"

    available_languages = fetch("/supported_languages").available_languages
    native_messages = fetch "#{translation_key_prefix}/#{DEVELOPMENT_LANGUAGE}"
    native_messages_with_count = fetch "/proposed_translations/#{DEVELOPMENT_LANGUAGE}"


    return DIV() if waiting_for(native_messages) || waiting_for(proposed_translations) || waiting_for(native_messages_with_count)

    to_translate = (k for k,v of native_messages when k != 'key')
    return DIV() if to_translate.length == 0 

    # sections = {"all": to_translate}
    sections = {}
    could_not_find = {}



    if !@props.forum_specific
      percentRank = (array, n) ->
        L = 0
        S = 0
        N = array.length

        for aa, i in array 
          if array[i] < n
            L += 1
          else if array[i] == n
            S += 1

        (L + (0.5 * S)) / N

      percentiles = {}
      uses = []
      for name,trans of native_messages_with_count.proposals 
        continue if name == 'key'
        if trans.accepted.uses_this_period + trans.accepted.uses_last_period > 0 
          uses.push trans.accepted.uses_this_period + trans.accepted.uses_last_period

      all_uses = uses.sort (a,b) -> a - b
      for name,trans of native_messages_with_count.proposals 
        continue if name == 'key'      

        uses = trans.accepted.uses_this_period + trans.accepted.uses_last_period
        if uses == 0
          rank = -1
        else 
          rank = percentRank(all_uses, uses) * 100
        percentiles[name] = rank 

      console.log {percentiles}


    local = fetch 'translations'
    for name in to_translate
      if local.filters?.length > 0 
        translation = proposed_translations.proposals[name]
        continue if 'Untranslated' in local.filters && !!translation
        continue if 'Not translated by you' in local.filters && !!translation?.yours
        continue if 'Under review' in local.filters && !translation?.proposals?.length > 0

        if !@props.forum_specific
          passes_use_range = false
          has_use_filter = false
          if 'High use' in local.filters
            has_use_filter = true
            passes_use_range ||= percentiles[name] >= 75
          if 'Medium use' in local.filters 
            has_use_filter = true
            passes_use_range ||= percentiles[name] >= 25 && percentiles[name] < 75
          if 'Low use' in local.filters 
            has_use_filter = true
            passes_use_range ||= percentiles[name] >= 0 && percentiles[name] < 25
          if 'Rarely used' in local.filters
            has_use_filter = true
            passes_use_range ||= percentiles[name] == -1

          continue if !passes_use_range && has_use_filter

      sp = name.split('.')
      if sp.length > 1
        sections[sp[0]] ||= []
        sections[sp[0]].push name
      else 
        sections.misc ||= []
        sections.misc.push name

    current_user = fetch '/current_user'

    if @props.forum_specific
      cols = ['Message', "Translation. Leave blank if Message already #{available_languages[lang]}"]
    else 
      cols = ['Message in English', "Translation to #{available_languages[lang]}"]

    DIV 
      style: 
        marginTop: 36

      H2 
        style: 
          fontSize: 22
          marginBottom: 12

        TRANSLATE 
          id: "translations.language_header"
          percent_complete: Math.round(translation_progress(lang, translation_key_prefix) * 100)
          language: available_languages[lang]
          "Translations for {language} ({percent_complete}% completed)"

      if current_user.is_super_admin

        DIV null,

          BUTTON
            onClick: =>  
              proposals = []
              for id, props of proposed_translations.proposals
                if props.proposals?.length > 0
                  latest = null
                  to_accept = null
                  candidates = props.proposals.slice()
                  if props.accepted
                    candidates.push props.accepted 
                  for proposal in candidates
                    if !latest || proposal.created_at > latest
                      latest = proposal.created_at
                      to_accept = proposal
                  if !to_accept.accepted
                    console.log "Promoting", to_accept.id, " over ", props.accepted?.id, "(#{proposal.created_at} over #{props.accepted?.created_at}"
                    to_accept['accepted'] = true
                    proposals.push to_accept

              if proposals.length > 0 
                updateTranslations proposals

            "Accept latest proposed translations"

          BUTTON 
            onClick: => 
              proposals = []
              for id, props of proposed_translations.proposals
                if props.proposals?.length > 0
                  for proposal in props.proposals
                    continue if proposal.accepted || (proposed_translations.accepted && proposal.translation == proposed_translations.accepted.translation)
                    console.log "Proposed to delete:", proposal
                    proposals.push proposal

              if proposals.length > 0 
                rejectProposals proposals

            "Clear proposals"


          BUTTON
            onClick: =>  
              proposals = []
              for id, props of proposed_translations.proposals
                if props.accepted
                  proposals.push props.accepted

              if proposals.length > 0 
                updateTranslations proposals

            "Propagate accepted"



      TABLE 
        style: 
          width: HOMEPAGE_WIDTH()

        TBODY null,



          for section, names of sections
            continue if names.length == 0
            names.sort()

            rows = []

            rows.push TR
              key: 'preamble'              
              TD 
                colSpan: cols.length 
                style: 
                  fontSize: 24
                  paddingTop: 12
                
                section.toUpperCase().replace /\_/g, ' '

                DIV 
                  style: 
                    fontSize: 12
                    marginBottom: 8
                  
                  "Translation strings support ICU format for e.g. pluralization. For complicated translations, you may wish to "
                  A 
                    href: "http://format-message.github.io/icu-message-format-for-translators/editor.html"
                    target: '_blank'
                    style: 
                      textDecoration: 'underline'
                    "use this helper"
                  "."


            rows.push TR 
              key: 'header'
              style: 
                backgroundColor: '#dfdfdf'


              for col in cols
                TH
                  key: col
                  style: 
                    textAlign: 'left'
                    padding: "4px 6px"
                  col

            for name, idx in names
              do (name, idx) => 
                no_id = name == native_messages[name]

                if !@props.forum_specific
                  percentile = percentiles[name]
                  if percentile >= 75 
                    use_color = 'red' 
                    use_label = 'high use'
                  else if percentile >= 25 
                    use_color = 'orange'
                    use_label = 'medium use'                  
                  else if percentile >= 0 
                    use_color = 'green'
                    use_label = 'low use'                  
                  else 
                    use_color = 'blue'
                    use_label = 'rarely used'


                rows.push TR 
                  key: "row-id-#{name}"
                  style: 
                    backgroundColor: if idx % 2 == 1 then '#f8f8f8'

                  TD 
                    style: 
                      padding: "2px 4px"
                      width: "40%"

                    DIV 
                      ref: "message-#{name}-#{idx}"
                      title: if no_id then 'no ID' else name 

                      "#{native_messages[name]}"

                      if !@props.forum_specific
                        SPAN 
                          style: 
                            color: use_color
                            fontSize: 12
                            paddingLeft: 12
                          use_label


                  TD  
                    style: 
                      width: '58%'
                      padding: "2px 4px"
                      position: 'relative'


                    DIV 
                      style: 
                        position: 'relative'

                      editable_translation name, lang, subdomain_id, updated_translations, proposed_translations.proposals[name]
                      if current_user.is_super_admin
                        do (name) =>
                          BUTTON 
                            style: 
                              fontSize: 14
                              backgroundColor: 'transparent'
                              border: 'none'
                              color: '#ccc'
                              position: 'absolute'
                              right: -25
                              padding: '4px'
                              top: 'calc(50% - 14px)'
                            onClick: => 
                              deleteTranslationString name
                              delete native_messages[name]
                              delete updated_translations[name]
                            "x"


                    if current_user.is_super_admin && proposed_translations.proposals[name]?.proposals.length > 0
                      UL  
                        style: {}

                        for proposal, idx in proposed_translations.proposals[name].proposals
                          do (proposal, name, idx) =>
                            LI 
                              key: "#{name}-#{proposal.translation}-#{proposal.id}"
                              style: 
                                padding: "2px 0px 8px 0px"
                                listStyle: 'none'

                              DIV 
                                style: {}
                                proposal.translation 


                              draw_translation_metadata(proposal)

                              BUTTON
                                style: 
                                  borderRadius: 8
                                onClick: => 
                                  proposal.accepted = true
                                  updateTranslations [proposal]

                                "Ok"

                              BUTTON
                                style: 
                                  backgroundColor: 'transparent'
                                  display: 'inline-block'
                                  marginLeft: 20
                                  border: 'none'
                                  color: '#999'
                                  textDecoration: 'underline'
                                  fontSize: 14

                                onClick: => 
                                  rejectProposals(name, [proposal])
                                "reject"

            rows

draw_translation_metadata = (proposal) -> 
  if proposal.user_id
    proposer = fetch("/user/#{proposal.user_id}")
  else 
    proposer = fetch('/current_user') 
  
  SPAN 
    style: 
      fontSize: 14
      color: "#aaa"
      paddingRight: 4
    "#{proposal.origin_server} - #{proposer.name or proposer.user or proposal.user_id} #{prettyDate(proposal.created_at)}"

updateTranslations = (proposals, cb) ->
  return if window.navigator.userAgent?.indexOf('Prerender') > -1

  frm = new FormData()
  frm.append "authenticity_token", arest.csrf()
  frm.append "proposals", JSON.stringify(proposals)

  xhr = new XMLHttpRequest
  xhr.addEventListener 'readystatechange', cb, false
  xhr.open 'PUT', '/translations', true
  xhr.onload = ->
    translation_cache = {}
    result = JSON.parse(xhr.responseText)
    arest.update_cache(result)

  xhr.send frm

deleteTranslationString = (string_id) -> 
  frm = new FormData()
  frm.append "authenticity_token", arest.csrf()
  frm.append "string_id", string_id

  xhr = new XMLHttpRequest
  xhr.addEventListener 'readystatechange', null, false
  xhr.open 'DELETE', '/translations', true
  xhr.onload = ->
    result = JSON.parse(xhr.responseText)
    arest.update_cache(result)

  xhr.send frm

rejectProposals = (proposals) -> 
  frm = new FormData()
  frm.append "authenticity_token", arest.csrf()
  frm.append "proposals", JSON.stringify(proposals)

  xhr = new XMLHttpRequest
  xhr.addEventListener 'readystatechange', null, false
  xhr.open 'DELETE', '/translation_proposal', true
  xhr.onload = ->
    result = JSON.parse(xhr.responseText)
    arest.update_cache(result)

  xhr.send frm


editable_translation = (id, lang_code, subdomain_id, updated_translations, proposed_translations, style) -> 
  current_user = fetch '/current_user'


  accepted = proposed = val = proposal = null 


  if proposed_translations
    if proposed_translations.accepted
      accepted = val = proposed_translations.accepted.translation
      proposal = proposed_translations.accepted
    if proposed_translations.yours
      proposed = val = proposed_translations.yours.translation
      proposal = proposed_translations.yours


  SPAN 
    key: "#{id}-#{accepted}-#{proposed}" 

    if accepted && proposed && accepted.user_id != proposed.user_id
      DIV null, 
          

        DIV 
          style: 
            fontStyle: 'italic'
            fontSize: 14

          "Current translation:"

        accepted 

        DIV 
          style: 
            fontStyle: 'italic'
            marginTop: 12
            fontSize: 14

          "Your proposed translation:"


    AutoGrowTextArea
      defaultValue: updated_translations[id]?.translation or val
      style: _.defaults (style or {}),
        verticalAlign: 'top'
        fontSize: 'inherit'
        width: '100%'
        borderColor: '#ddd'
      onChange: (e) -> 
        trans = e.target.value
        if !updated_translations[id]
          updated_translations[id] = 
            string_id: id
            lang_code: lang_code
            subdomain_id: subdomain_id
            translation: e.target.value 
        else  
          updated_translations[id].translation = e.target.value 

    if proposal
      draw_translation_metadata proposal


promote_temporary_translations = (key) ->

  updated_translations = fetch key

  proposals = []
  for k,v of updated_translations
    continue if k == 'key'
    proposals.push v

  return if proposals.length == 0

  updateTranslations proposals, -> 
    trans_UI = fetch('translations_interface')
    trans_UI.saved_successfully = true 
    save trans_UI 
    _.delay ->
      trans_UI.saved_successfully = false
      save trans_UI
    , 4000




window.TranslationsDash = TranslationsDash
