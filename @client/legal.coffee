
GoogleDocEmbed = ReactiveComponent
  displayName: 'GoogleDocEmbed'

  render: -> 

    DIV null,
      IFRAME 
        ref: 'iframe'
        width: '100%'
        height: window.innerHeight
        src: @props.link


window.PrivacyPolicy = -> 
  GoogleDocEmbed 
    link: 'http://gdoc.pub/1SrdA9h2JuyJxINCOmWyBP-Wi9Q-aTzp-AjShrpXJVIw'

window.TermsOfService = -> 
  GoogleDocEmbed 
    link: 'http://gdoc.pub/1fTnbT7ZsLRAKoONN11pOdYZvSxM0PLPCmedTeUHBVL0'

