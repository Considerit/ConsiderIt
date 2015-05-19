require './shared'

window.GodMode = ReactiveComponent
  displayName: 'GodMode'

  render : -> 
    godmode = fetch 'godmode'

    return SPAN null if !godmode.enabled

    users = fetch '/users'

    if !@local.switch_user?
      @local.switch_user = true
      save @local

    DIV 
      style: 
        position: 'absolute'
        zIndex: 9999
        left: 0
        top: 0
        width: '100%'
        backgroundColor: 'black'
        color: 'white'
        padding: 10

      onMouseLeave: => 
        @local.switch_user = false
        save @local

      SPAN 
        style: 
          fontWeight: 300
          color: 'cyan'
          display: 'inline-block'
          fontSize: 28
          marginRight: 20
        'GODMODE'


      A
        style:
          fontWeight: 'bold'
        onMouseEnter: => 
          @local.switch_user = true
          save @local

        'Switch user'

      if @local.switch_user
        UL 
          style: 
            width: '100%'

          for user in users.users
            LI 
              style: 
                backgroundColor: 'black'
                listStyle: 'none'
                display: 'inline-block'
                margin: 10
                cursor: 'pointer'
              onClick: do(user) => => 
                current_user = fetch '/current_user'
                current_user.trying_to = 'switch_users'
                current_user.switch_to = user
                save current_user, -> 
                  location.reload()

                @local.switch_user = false
                save @local
                godmode.enabled = false
                save godmode

              Avatar 
                key: user
                user: user
                hide_tooltip: true
                style: 
                  width: 50
                  height: 50

              SPAN
                style: 
                  paddingTop: 12
                  paddingLeft: 5
                  display: 'inline-block'

                fetch(user).name


  componentDidMount : ->
    document.addEventListener "keypress", (e) -> 
      key = (e and e.keyCode) or e.keyCode

      if key==21 # cntrl-U       
        godmode = fetch 'godmode'
        godmode.enabled = !godmode.enabled
        save godmode 
