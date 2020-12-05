require './profile_menu'
require './customizations'
require './banner'


window.Header = ReactiveComponent
  displayName: 'Header'

  render : ->
    current_user = fetch('/current_user')
    subdomain = fetch('/subdomain')

    auth = fetch('auth')
    return SPAN null if auth.form && auth.form not in ['edit profile']

    is_homepage = fetch('location').url == '/'
    editing_banner = fetch('edit_banner').editing

    HEADER 
      className: if !is_light_background() then 'dark'

      # DIV 
      #   id: 'upgrade-message'
      #   style: 
      #     backgroundColor: 'black'
      #     color: 'white'
      #     padding: 10
      #     fontSize: 24
      #     textAlign: 'center'

      #   "Consider.it server upgrade scheduled for 5:30pm - 6:00pm UTC"
      
      customization('header_bonus')?()
      DIV 
        style: 
          position: 'relative'
          zIndex: 2
          margin: '0 auto'
          backgroundColor: 'white'


        ProfileMenu()

        if customization('google_translate_style') && fetch('location').url == '/'
          DIV 
            style: 
              position: 'absolute'
              left: 40
              zIndex: 2
            GoogleTranslate()



        if is_homepage && customization('HomepageHeader')
          customization('HomepageHeader').apply(@)
        else 
          customization('SiteHeader').apply(@)

        DIV 
          style: 
            backgroundColor: '#eee'
            color: '#f00'
            padding: '5px 20px'
            display: if @root.server_error then 'block' else 'none'

          translator "engage.server_error", 'Warning: there was a server error!'





