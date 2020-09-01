require './customizations'


window.translation_progress = (lang, key_prefix) -> 
  key_prefix ||= '/translations'
  translations = fetch "#{key_prefix}/#{lang}"
  dev_language = fetch "#{key_prefix}/en"

  messages =   (k for k,v of dev_language when v.txt?.length > 0 or v.proposals?[0]?.txt?.length > 0)
  translated = (k for k,v of translations when v.txt?.length > 0 or v.proposals?[0]?.txt?.length > 0)

  translated.length / messages.length



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
  {message, lang_used, target_lang} = T args, native_text 

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
    IN_SITU_TRANSLATOR _.extend({lang_used, target_lang, message, native_text}, args), translation

IN_SITU_TRANSLATOR = ReactiveComponent
  displayName: 'InSituTranslator'
  render: ->
    key = @props.key or '/translations'
    target_lang = @props.target_lang

    translated = @props.lang_used == target_lang
    id = @props.id or @props.native_text
    available_languages = fetch('/translations').available_languages
    SPAN 
      style: 
        backgroundColor: if translated then "rgba(166, 195, 151, .5)" else "rgba(251,124,124,.5)"
        position: 'relative'
      onMouseOver: =>
        @local.show_translator = true 
        save @local

      @props.children

      if @local.show_translator
        updated_translations = get_temporary_translations target_lang, key
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

            editable_translation id, updated_translations, message_style


          BUTTON 
            className: "primary_button"
            style: 
              backgroundColor: focus_color()
              fontSize: 14
            onClick: => 
              promote_temporary_translations(target_lang, key)
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

window.T = window.t = window.translator = (args, native_text) -> 
  # user = fetch '/current_user'
  subdomain = fetch '/subdomain'


  if typeof args == "string"
    if native_text
      args = {id: args}
    else 
      native_text = args 
      args = {}

  id = args.id or native_text
  translations_key_prefix = args.key or "/translations"

  translations_native = fetch "#{translations_key_prefix}/#{DEVELOPMENT_LANGUAGE}"

  return '...' if waiting_for(translations_native)

  native_text = native_text.replace(/\n/g, "")

  # ensure this string is in the translations database for the development language
  if translations_native[id]?.txt != native_text
    console.log 'updating', {id, native_text, saved: translations_native[id]?.txt}, translations_native[id]?.txt == native_text
    translations_native[id] ||= {}
    translations_native[id].txt = native_text
    save translations_native  

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
      message = translations[id].txt
      # if this user has proposed one, use that
      if translations[id].proposals?.length > 0
        u = fetch('/current_user').user
        for proposal in translations[id].proposals
          if proposal.u == u 
            message = proposal.txt 
      if message
        lang_used = lang 
        break 

  try 
    translator = new IntlMessageFormat.IntlMessageFormat message, lang_used
    message = translator.format(args)

  catch e
     # this is a bad fallback, as plural rules won't work
    message = translations_native[id]?.txt


  if args.return_lang_used # useful for a T wrapper that enables in situ translations
    {message, lang_used, target_lang: langs[0]}
  else 
    message


TranslationsDash = ReactiveComponent
  displayName: 'TranslationsDash'

  render : ->

    subdomain = fetch '/subdomain'
    current_user = fetch '/current_user'
    translations = fetch '/translations'

    return DIV() if !translations.available_languages

    local = fetch 'translations'

    all_langs = ( [k,v] for k,v of translations.available_languages when k != DEVELOPMENT_LANGUAGE)
    if current_user.is_super_admin
      all_langs.push ['pseudo-en', "Pseudo English (for testing)"]

    if !local.translating_lang
      if subdomain.lang && subdomain.lang != 'en'
        local.translating_lang = subdomain.lang 
      else 
        local.translating_lang = all_langs[0][0]

    DIV null, 

      DashHeader name: 'Translations'

      DIV style: {width: HOMEPAGE_WIDTH(), margin: '0px auto'},

        DIV style: {},
          "ConsiderIt's native development language is English (en). Please help us translate it to your language!"

        DIV 
          style: 
            marginTop: 24

          "Which language do you wish to translate for?"


          SELECT 
            value: local.translating_lang
            style: 
              fontSize: 20
              marginLeft: 14
              display: 'inline-block'
            onChange: (ev) => 
              local.translating_lang = ev.target.value
              save local

            for [k,v] in all_langs
              OPTION 
                value: k
                "#{v} (#{k})"

          DIV 
            style: 
              fontSize: 12
            "Is your language not available? Email us at hello@consider.it to get your language added."


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
                  abbrev = @refs.newlang_abbrev.getDOMNode().value
                  label = @refs.newlang_label.getDOMNode().value

                  if abbrev not of translations.available_languages
                    translations.available_languages[abbrev] = label 
                    save translations

                    @refs.newlang_abbrev.getDOMNode().value = ""
                    @refs.newlang_label.getDOMNode().value = ""

                "Add"


        if local.translating_lang
          DIV null, 

            TranslationsForLang
              key: "translations_for_#{local.translating_lang}"
              translation_key_prefix: "/translations"
              lang: local.translating_lang

            # if current_user.is_admin 
            TranslationsForLang
              key: "forum_translations_for_#{local.translating_lang}"            
              translation_key_prefix: "/translations/#{subdomain.name}"
              lang: local.translating_lang
              forum_specific: true


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
                className: 'primary_button'
                style: 
                  backgroundColor: focus_color()
                  marginTop: 0
                  fontSize: 22
                onClick: => 
                  promote_temporary_translations(local.translating_lang, "/translations")                  
                  promote_temporary_translations(local.translating_lang, "/translations/#{subdomain.name}")
                
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

    available_languages = fetch("/translations").available_languages
    native_messages = fetch "#{@props.translation_key_prefix}/#{DEVELOPMENT_LANGUAGE}"
    translations = fetch "#{@props.translation_key_prefix}/#{lang}"

    return DIV() if waiting_for(native_messages) || waiting_for(translations)

    to_translate = (k for k,v of native_messages when k != 'key')
    return DIV() if to_translate.length == 0 

    # create local copy of proposed translations before saving
    # TODO: I think this is making a shallow clone, which means that updated_translations and translations might 
    #       point to the same {txt, proposals} objects. 
    updated_translations = get_temporary_translations(lang, @props.translation_key_prefix)


    # sections = {"all": to_translate}
    sections = {}
    for name in to_translate
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
          percent_complete: Math.round(translation_progress(lang, @props.translation_key_prefix) * 100)
          language: available_languages[lang]
          "Translations for {language} ({percent_complete}% completed)"

      if current_user.is_super_admin
        BUTTON
          onClick: =>  
            for name,v of updated_translations
              if v.proposals?.length > 0
                # accept the latest one
                idx = v.proposals.length - 1
                proposal = v.proposals[idx]
                v.txt = proposal.txt 
                v.u = proposal.u
                v.proposals.splice(idx, 1)
            save updated_translations
          "Accept all proposed translations"


      TABLE 
        style: 
          width: HOMEPAGE_WIDTH()

        TBODY null,



          for section, names of sections
            names.sort()

            rows = []

            rows.push TR null,              
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
              style: 
                backgroundColor: '#dfdfdf'


              for col in cols
                TH
                  style: 
                    textAlign: 'left'
                    padding: "4px 6px"
                  col

            for name, idx in names
              do (name, idx) => 
                no_id = name == native_messages[name].txt
                rows.push TR 
                  key: "row-id-#{name}"
                  style: 
                    backgroundColor: if idx % 2 == 1 then '#f8f8f8'

                  TD 
                    style: 
                      padding: "2px 4px"
                      width: "40%"
                      # display: 'inline-block'
                      # verticalAlign: 'top'

                    do (name, idx) => 
                      show_tooltip = => 
                        tooltip = fetch 'tooltip'
                        node = @refs["message-#{name}-#{idx}"]
                        if node 
                          tooltip.coords = $(node.getDOMNode()).offset()
                          tooltip.tip = if no_id then 'no ID' else name 
                          save tooltip

                      hide_tooltip = => 
                        tooltip = fetch 'tooltip'
                        tooltip.coords = null
                        save tooltip

                      DIV 
                        ref: "message-#{name}-#{idx}"
                        onFocus: show_tooltip
                        onMouseEnter: show_tooltip
                        onBlur: hide_tooltip
                        onMouseLeave: hide_tooltip

                        "#{native_messages[name].txt}"

                  TD  
                    style: 
                      width: '58%'
                      padding: "2px 4px"
                      position: 'relative'

                    # width: "42%"
                    # display: 'inline-block'
                    # verticalAlign: 'top'


                    editable_translation name, updated_translations
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
                          onClick: => 
                            delete native_messages[name]
                            delete updated_translations[name]
                            save updated_translations
                            save native_messages
                          "x"


                    if current_user.is_super_admin && updated_translations[name]?.proposals
                      UL  
                        style: {}

                        for proposal, idx in updated_translations[name].proposals
                          do (proposal, name, idx) =>
                            if proposal.u 
                              proposer = fetch(proposal.u)
                            else 
                              proposer = current_user 
                            LI 
                              style: 
                                padding: "2px 0px 8px 0px"
                                listStyle: 'none'

                              DIV 
                                style: {}
                                proposal.txt 

                              SPAN 
                                style: 
                                  fontSize: 14
                                  color: "#aaa"
                                  paddingRight: 4
                                "by #{proposer.name or proposer.user}"

                              BUTTON
                                style: 
                                  borderRadius: 8
                                onClick: => 
                                  updated_translations[name].txt = proposal.txt 
                                  updated_translations[name].u = proposal.u
                                  updated_translations[name].proposals.splice(idx, 1)
                                  save updated_translations
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
                                  updated_translations[name].proposals.splice(idx, 1)
                                  save updated_translations
                                "reject"

            rows




window.get_temporary_translations = (lang, key) ->
  key ||= '/translations'
  translations = fetch "#{key}/#{lang}"
  _.defaults fetch("local#{translations.key}"), JSON.parse(JSON.stringify(translations))


editable_translation = (id, updated_translations, style) -> 
  current_user = fetch '/current_user'


  accepted = proposed = val = null 

  if updated_translations[id]?.txt 
    accepted = val = updated_translations[id].txt
  
  if updated_translations[id]?.proposals
    for proposal in updated_translations[id].proposals
      if proposal.u == current_user.user 
        proposed = val = proposal.txt 

  SPAN 
    key: "#{id}-#{updated_translations[id]?.proposals?.length}" 

    if accepted && proposed 
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
      defaultValue: val
      style: _.defaults (style or {}),
        verticalAlign: 'top'
        fontSize: 'inherit'
        width: '100%'
        borderColor: '#ddd'
      onChange: (e) -> 
        trans = e.target.value
        updated_translations[id] ||= {}

        if current_user.is_super_admin
          updated_translations[id].txt = trans 
          updated_translations[id].u = current_user.user 
        else 
          updated_translations[id].proposals ||= []
          found = false 
          for proposal in updated_translations[id].proposals
            if proposal.u == current_user.user 
              proposal.txt = trans 
              found = true 
              break 
          if !found 
            updated_translations[id].proposals.unshift {txt: trans, u: current_user.user}


        save updated_translations



promote_temporary_translations = (lang, key) ->
  key ||= '/translations'
  translations = fetch "#{key}/#{lang}"
  updated_translations = fetch "local#{translations.key}"
  Object.assign translations, updated_translations
  translations.key = "#{key}/#{lang}"
  save translations, -> 
    trans_UI = fetch('translations_interface')
    trans_UI.saved_successfully = true 
    save trans_UI 
    _.delay ->
      trans_UI.saved_successfully = false
      save trans_UI
    , 4000




window.TranslationsDash = TranslationsDash
