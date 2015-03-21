require './activerest-m'
require './auth'
require './avatar'
require './browser_hacks'
require './browser_location'
require './tooltip'
require './shared'

SaasHomepage = ReactiveComponent
  displayName: 'SaasHomepage'

  render : -> 
    SPAN null


Header = ReactiveComponent
  displayName: 'Header'

  render : ->
    current_user = fetch('/current_user')

    DIV 
      style: 
        position: 'relative'
        margin: '0 auto'
        backgroundColor: logo_red
        minWidth: PAGE_WIDTH
        height: 52
    
      IMG 
        src: asset('saas/considerit_logo.svg')
        style: 
          position: 'relative'
          top: 8
          left: 12

######
# Page
# Decides which page to render by reading state (particularly location and auth). 
# Plays the role of an application router.
#
Page = ReactiveComponent
  displayName: 'Page'
  mixins: [AccessControlled]

  render: ->
    subdomain = fetch('/subdomain')
    loc = fetch('location')
    auth = fetch('auth')

    DIV 
      style: 
        minWidth: PAGE_WIDTH
        minHeight: 200
        zIndex: 2
        margin: 'auto'

      if auth.form
        Auth()

      else if !@accessGranted()
        SPAN null 
          
      else
        switch loc.url
          when '/'
            SaasHomepage key: 'homepage'
          when '/dashboard/create_subdomain'
            CreateSubdomain key: "/page/dashboard/create_subdomain"


Root = ReactiveComponent
  displayName: 'Root'

  render : -> 

    subdomain = fetch '/subdomain'
    loc = fetch('location')

    DIV 
      onClick: @resetSelection

      BrowserLocation()

      if !subdomain.name
        LOADING_INDICATOR

      else 
        auth = fetch('auth')

        DIV 
          style:
            minWidth: PAGE_WIDTH
            backgroundColor: 'white'
            overflowX: 'hidden'
          
          BrowserHacks()

          Header()        

          Page key: "/page#{loc.url}"


      Tooltip()



# exports...
window.Saas = Root

require './application_loader'
