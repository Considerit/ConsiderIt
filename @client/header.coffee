require './profile_menu'
require './customizations'
require './banner'


window.Header = ReactiveComponent
  displayName: 'Header'

  render : ->
    current_user = fetch('/current_user')
    subdomain = fetch('/subdomain')


    root = fetch('root')


    # auth = fetch('auth')
    # return SPAN null if auth.form && auth.form not in ['edit profile']

    return SPAN null if !subdomain.name || embedded_demo()


    
    loc = fetch('location')
    is_homepage = EXPAND_IN_PLACE || loc.url == '/'
    

    header_bonus = customization('header_bonus') # currently used for things like inserting google font

    HEADER 
      style: 
        position: 'relative'
        zIndex: if fetch('edit_forum').editing then 1 # necessary b/c of payment modal
      className: if !is_light_background() then 'dark'

      if current_user.is_admin
        HostHeader()


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
            display: if root.server_error then 'block' else 'none'

          translator "engage.server_error", 'Warning: there was a server error!'


window.HostHeader = ReactiveComponent
  displayName: 'HostHeader'

  render: ->
    loc = fetch('location')
    edit_forum = fetch('edit_forum')

    free_forum = permit('configure paid feature') < 0

    if edit_forum.editing 

      DIV 
        className: 'forum_editor'
        style: 
          #display: 'flex'
          #justifyContent: 'center'
          #alignItems: 'center'
          padding: 8
          textAlign: 'center'

        if window.UpgradeForumCompact? && free_forum
          UpgradeForumCompact()

        EditForum()

    else if loc.url.startsWith('/dashboard') && window.UpgradeForumBanner? && free_forum
      UpgradeForumBanner()

    else 
      DIV null



