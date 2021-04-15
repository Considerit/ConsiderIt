require './shared'

window.SU = ReactiveComponent
  displayName: 'SU'

  render : -> 
    su = fetch 'su'

    return SPAN null if !su.enabled

    users = fetch '/users'

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
        su.enabled = false 
        save su

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

              su.enabled = false
              save su

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
    document.addEventListener "keyup", (e) -> 

      key = (e and e.keyCode) or e.keyCode
      if key==85 && e.ctrlKey # cntrl-U       
        su = fetch 'su'
        su.enabled = !su.enabled
        save su 
