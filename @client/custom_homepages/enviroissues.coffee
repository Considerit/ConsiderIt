window.HomepageHeader = ReactiveComponent
  displayName: 'HomepageHeader'

  render: ->
    loc = fetch 'location'
    homepage = loc.url == '/'

    DIV
      style:
        width: CONTENT_WIDTH()
        margin: '20px auto'
        position: 'relative'

      back_to_homepage_button
        display: 'inline-block'
        fontSize: 43
        visibility: if homepage then 'hidden'
        verticalAlign: 'top'
        marginTop: 22
        marginRight: 15
        color: '#888'


      IMG
        src: asset('enviroissues/logo.png')

      DIV 
        style: 
          position: 'absolute'
          top: 18
          right: 0
          width: 110

        ProfileMenu()

window.NonHomepageHeader = window.HomepageHeader