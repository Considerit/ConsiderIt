window.HomepageHeader = ReactiveComponent
  displayName: 'HomepageHeader'

  render: ->
    DIV style: {textAlign: 'center'},
      STYLE null, 
        '.banner_link {color: #78d18b; font-weight: 600; text-decoration: underline;}'

      ProfileMenu()

      DIV 
        style: 
          color: '#707070'
          fontSize: 32
          padding: '20px 0'
          margin: '0px auto 0 auto'
          fontWeight: 800
          textTransform: 'uppercase'
          position: 'relative'
          width: CONTENT_WIDTH()
        'Help plan '
        A className: 'banner_link', href: 'http://riverterracetigard.com/', 'River Terrace'
        ', Tigard\'s newest neighborhood' 
