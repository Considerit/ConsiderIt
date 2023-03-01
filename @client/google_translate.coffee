# Unfortunately, google makes it so there can only be one Google Translate Widget 
# rendered into a page. So we have to move around the same element, rather than 
# embed it nicely where we want. 

styles += """
  .google-translate-candidate-container {
    height: 25px;
    min-width: 190px;
  }
  .translation_consent {
    white-space: nowrap;
    border-radius: 8px;
    border: none;
    padding: 4px 12px;
    font-size: 14px;
    box-shadow: 0 1px 3px rgb(0 0 0 / 60%);    
  }
"""
window.GoogleTranslate = ReactiveComponent
  displayName: 'GoogleTranslate'

  render: -> 
    return SPAN null if embedded_demo() || customization('disable_google_translate')

    style = if customization('google_translate_style') && is_a_dialogue_page() 
              s = JSON.parse JSON.stringify customization('google_translate_style')
              delete s.prominent if s.prominent
              delete s.callout if s.callout
              s
            else 
              _.defaults {}, @props.style, 
                textAlign: 'center'
                #marginBottom: 10

    @local.left ?= -9999

    DIV 
      style: 
        position: 'absolute'
        left: @local.left 
        top: @local.top
        zIndex: 9

      STYLE 
        dangerouslySetInnerHTML: __html: """

        """        
           
      DIV 
        key: "google_translate_element_#{@local.key}"
        id: "google_translate_element_#{@local.key}"
        ref: 'translation_el'
        style: style

        if !@local.show_google_translate
          BUTTON 
            className: 'translation_consent'
            onClick: => 
              confirmation = """
                Loading Google Translate will add third-party cookies to facilitate the language translation. Press Ok if you consent.\r\n\r\n
                Cargar Google Translate agregará cookies de terceros para facilitar la traducción del idioma. Presiona Ok si estás de acuerdo.\r\n \r\n
                Le chargement de Google Traduction ajoutera des cookies tiers pour faciliter la traduction de la langue. Appuyez sur OK si vous êtes d'accord.
              """

              if confirm(translator("translation.google_translate_consent", confirmation))
                @local.show_google_translate = true 
                save @local
            translator("translation.enable_language_translation", "Load Language Translator")


  downloadGoogleTranslate: ->
    lazyLoadJavascript "https://translate.google.com/translate_a/element.js", 
      onload: => 
        @int = setInterval => 
          if google?.translate?.TranslateElement?
            @insertTranslationWidget()
            @setPosition()
            clearInterval @int 
        , 20



  insertTranslationWidget: -> 
    subdomain = fetch '/subdomain'

    new google.translate.TranslateElement {
        pageLanguage: subdomain.lang
        layout: google.translate.TranslateElement.InlineLayout[if WINDOW_WIDTH() < 1180 then 'VERTICAL' else 'SIMPLE']
        multilanguagePage: true
        # gaTrack: #{Rails.env.production?}
        # gaId: 'UA-55365750-2'
      }, "google_translate_element_#{@local.key}"

  setPosition: -> 
    wrapper = document.querySelector '.google-translate-candidate-container'
    translate_el = google?.translate?.TranslateElement

    return if !wrapper || customization('disable_google_translate') 

    set_coords = (coords) =>
      left = coords.left + coords.width / 2 - @refs.translation_el.clientWidth / 2
      top = coords.top

      # set by Google Translate when a language is selected, which screws up the top calculation
      if document.body.style.top == "40px" 
        top -= 40

      if @local.left != left || top != @local.top
        @local.left = left
        @local.top = top
        save @local   

    observer = new IntersectionObserver (entries) =>
      for entry in entries
        coords = entry.boundingClientRect
        coords.left += window.pageXOffset
        coords.top += window.pageYOffset
        set_coords
          left: coords.left + window.pageXOffset
          top: coords.top + window.pageYOffset
          width: coords.width
      observer.disconnect()
    observer.observe(wrapper)




  componentDidMount: -> 
    return if customization('disable_google_translate')
    # location of this element will shadow the position of the first instance
    # of an element with a class of google-translate-candidate-container
    @placer_int = setInterval =>
      requestAnimationFrame @setPosition
    , 500

  componentDidUpdate: -> 
    return if customization('disable_google_translate')

    if @local.show_google_translate && !@translate_loaded
      @translate_loaded = true
      @downloadGoogleTranslate()



  componentWillUnmount: ->
    if @int || @placer_int 
      clearInterval @int
      clearInterval @placer_int