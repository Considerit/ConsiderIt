# Unfortunately, google makes it so there can only be one Google Translate Widget 
# rendered into a page. So we have to move around the same element, rather than 
# embed it nicely where we want. 

styles += """
  .google-translate-candidate-container {
    height: 25px;
    min-width: 190px;
  }
"""
window.GoogleTranslate = ReactiveComponent
  displayName: 'GoogleTranslate'

  render: -> 
    loc = fetch 'location'
    homepage = loc.url == '/'

    return SPAN null if embedded_demo()

    style = if customization('google_translate_style') && homepage 
              s = JSON.parse JSON.stringify customization('google_translate_style')
              delete s.prominent if s.prominent
              delete s.callout if s.callout
              s
            else 
              _.defaults {}, @props.style, 
                textAlign: 'center'
                marginBottom: 10

    DIV 
      style: 
        position: 'absolute'
        left: @local.left 
        top: @local.top
        zIndex: 9
           
      DIV 
        key: "google_translate_element_#{@local.key}"
        id: "google_translate_element_#{@local.key}"
        ref: 'translation_el'
        style: style

  insertTranslationWidget: -> 
    subdomain = fetch '/subdomain'


    new google.translate.TranslateElement {
        pageLanguage: subdomain.lang
        layout: google.translate.TranslateElement.InlineLayout.SIMPLE
        multilanguagePage: true
        # gaTrack: #{Rails.env.production?}
        # gaId: 'UA-55365750-2'
      }, "google_translate_element_#{@local.key}"

  componentDidMount: -> 

    @int = setInterval => 
      if google?.translate?.TranslateElement?
        @insertTranslationWidget()
        clearInterval @int 
    , 20

    # location of this element will shadow the position of the first instance
    # of an element with a class of google-translate-candidate-container
    @placer_int = setInterval =>
      wrapper = document.querySelector '.google-translate-candidate-container'
      translate_el = google?.translate?.TranslateElement

      return if !wrapper || !translate_el

      coords = getCoords(wrapper)

      left = coords.left + coords.width / 2 - @refs.translation_el.clientWidth / 2
      top = coords.top

      # set by Google Translate when a language is selected, which screws up the top calculation
      if document.body.style.top == "40px" 
        top -= 40

      if @local.left != left || top != @local.top
        @local.left = left
        @local.top = top
        save @local
    , 500

  componentWillUnmount: ->
    clearInterval @int
    clearInterval @placer_int