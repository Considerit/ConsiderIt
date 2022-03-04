# Unfortunately, google makes it so there can only be one Google Translate Widget 
# rendered into a page. So we have to move around the same element, rather than 
# embed it nicely where we want. 
window.GoogleTranslate = ReactiveComponent
  displayName: 'GoogleTranslate'

  render: -> 
    loc = fetch 'location'
    homepage = loc.url == '/'

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
        display: if !customization('google_translate_style') then 'none'

      # SCRIPT 
      #   type: 'text/javascript'
      #   src: 'https://translate.google.com/translate_a/element.js' 
           
      DIV 
        key: "google_translate_element_#{@local.key}"
        id: "google_translate_element_#{@local.key}"
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

  componentWillUnmount: ->
    clearInterval @int