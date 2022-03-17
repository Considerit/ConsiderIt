require './profile_menu'
require './customizations'
require './banner'


window.Header = ReactiveComponent
  displayName: 'Header'

  render : ->
    current_user = fetch('/current_user')
    subdomain = fetch('/subdomain')

    # auth = fetch('auth')
    # return SPAN null if auth.form && auth.form not in ['edit profile']

    loc = fetch('location')
    is_homepage = loc.url == '/'
    editing_banner = fetch('edit_banner').editing

    header_bonus = customization('header_bonus') # currently used for things like inserting google font

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
      
      header_bonus?()
      DIV 
        style: 
          margin: '0 auto'


        ProfileMenu()

        if customization('google_translate_style') && !customization('google_translate_style').prominent && fetch('location').url == '/'
          DIV 
            className: 'google-translate-candidate-container'
            style: 
              position: 'absolute'
              left: 40
              zIndex: 2


        if is_homepage
          EditBanner()

        if is_homepage
          (customization('HomepageHeader') or customization('SiteHeader') or PhotoBanner).apply(@)
        else
          ShortHeader
            background: 'white'
            text: ''
            logo_src: false

        DIV 
          style: 
            backgroundColor: '#eee'
            color: '#f00'
            padding: '5px 20px'
            display: if @root.server_error then 'block' else 'none'

          translator "engage.server_error", 'Warning: there was a server error!'





