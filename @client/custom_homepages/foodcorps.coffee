FoodcorpsHeader = ReactiveComponent
  displayName: 'FoodcorpsHeader'

  render: -> 
    loc = fetch('location')

    homepage = loc.url == '/'

    DIV 
      style: 
        position: 'relative'
        height: 200

      IMG
        src: asset('foodcorps/logo.png')
        style:
          height: 160
          position: 'absolute'
          top: 10
          left: (WINDOW_WIDTH() - CONTENT_WIDTH()) / 2
          zIndex: 5


      DIV
        style:
          background: "url(#{asset('foodcorps/bg.gif')}) repeat-x"
          height: 68
          width: '100%'
          position: 'relative'
          top: 116
          left: 0

      back_to_homepage_button
        display: 'inline-block'
        fontSize: 43
        visibility: if homepage then 'hidden'
        verticalAlign: 'top'
        marginTop: 52
        marginLeft: 15
        color: 'white'
        zIndex: 10
        position: 'relative'

      DIV 
        style: 
          position: 'absolute'
          top: 18
          right: 0
          width: 110

        ProfileMenu()

window.HomepageHeader = window.NonHomepageHeader = FoodcorpsHeader