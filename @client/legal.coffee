
GoogleDocEmbed = ReactiveComponent
  displayName: 'GoogleDocEmbed'

  render: -> 

    DIV 
      style: 
        width: '80%'
        margin: 'auto'
        maxWidth: 700
      IFRAME 
        ref: 'iframe'
        width: '100%'
        height: window.innerHeight
        src: @props.link

LegalDoc = ReactiveComponent
  displayName: 'LegalDoc'

  render: ->

    html = fetch("/legal/#{@props.name}").html
    return SPAN(null) if !html

    DIV 
      style: 
        width: '80%'
        margin: '40px auto'
        maxWidth: 1000
        padding: '25px 60px'
        backgroundColor: 'white'
        boxShadow: '0 1px 2px rgba(0,0,0,.2)'

      STYLE dangerouslySetInnerHTML: __html: #dangerously set html is so that the type="text" doesn't get escaped
          """
          .legaldoc .title {font-size: 36px; font-weight: bold; margin-bottom: 10px; margin-top: 20px}
          .legaldoc h1 {font-size: 28px; font-weight: 600; margin-bottom: 10px; margin-top: 20px}
          .legaldoc h2 {font-size: 20px; font-weight: 500; margin-bottom: 10px; margin-top: 20px}
          .legaldoc ul {list-style-position: outside; padding-left: 40px;}
          .legaldoc p {padding-top: 5px; padding-bottom: 5px;}
          .legaldoc a {text-decoration: underline; color:#{logo_red};}
          """


      DIV className: 'legaldoc', dangerouslySetInnerHTML: {__html: html.replace(/hello@consider.it/g, '<a href="mailto:hello@consider.it">hello@consider.it</a>')}

    

window.PrivacyPolicy = -> 
  LegalDoc 
    name: "privacy_policy"


window.TermsOfService = -> 
  LegalDoc 
    name: "terms_of_service"




