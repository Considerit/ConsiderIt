######
# Development 
#
# Adds an invisible development menu in dev environments that shows up when
# you move the mouse into the upper right of the page

require './shared'

Development = ReactiveComponent
  displayName: 'Development'

  render : -> 

    if !@local.search 
      @local.search = ''

    if !@local.only_with_activity?
      @local.only_with_activity = true 

    subdomains = fetch('/subdomains').subs
    subdomains = (s for s in subdomains when (!@local.only_with_activity || s.activity) && (!@local.highlight_customized || s.customizations))

    apps = fetch '/apps'
    app = fetch '/application'

    hues = getNiceRandomHues Math.max(subdomains?.length, apps.apps?.length)
    submenus = if app.app == 'franklin' 
                ['change subdomain', 'change application']
               else if app.app == 'product_page'
                ['change application']
    
    subdomains.sort((a,b) -> if a.name.toLowerCase() > b.name.toLowerCase() then 1 else -1)

    DIV 
      style: 
        position: 'absolute'
        zIndex: 9999
        left: 0
        top: 0
        opacity: if @local.hover_top then 1 else 0
        backgroundColor: 'black'
        color: 'white'
        padding: 15
      tabIndex: 0 

      onTouchEnd: (e) => @local.hover_top = true; save @local
      onMouseEnter: (e) => @getDOMNode().focus(); @local.hover_top = true; save @local
      onMouseLeave: (e) => @local.search = ''; @local.hover_top = @local.hover_second = false; save @local

      onKeyDown: (e) => 
        if e.which == 27 # esc
          @local.search = ''; @local.hover_top = @local.hover_second = false; save @local
        else if e.which == 8 || e.which == 46 # backspace / delete 
          @local.search = @local.search.substring(0, @local.search.length - 1)
        else if e.which == 9 # tab 
          @local.only_with_activity = !@local.only_with_activity
        else if e.which == 32 # space
          @local.highlight_customized = !@local.highlight_customized
        else if e.key.length == 1 && /[a-zA-Z0-9-_ ]/.test e.key
          @local.search += e.key

        save @local
        e.preventDefault()  

      if @local.hover_top
        DIV null,
          UL
            style: 
              listStyle: 'none'
              display: 'inline-block'

            for submenu in submenus
              LI
                style:
                  display: 'inline-block'
                  padding: '0px 18px'
                  backgroundColor: 'black'
                  color: 'white'
                  fontWeight: 600
                onTouchEnd: do(submenu) => (e) => 
                  @local.hover_second = submenu
                  save @local
                onMouseEnter: do(submenu) => (e) => 
                  @local.hover_second = submenu
                  save @local

                submenu  

            LI 
              style: 
                paddingLeft: 20
                backgroundColor: 'black'
                color: 'white'
                display: 'inline-block'

              @local.search    

          DIV 
            style: 
              width: '100%'  

            if @local.hover_second == 'change subdomain'                
              UL null,
                for sub, idx in subdomains
                  LI
                    style: 
                      display: 'inline-block'
                      listStyle: 'none'
                    A
                      href: "/change_subdomain/#{sub.id}"
                      'data-nojax': false
                      style: 
                        padding: "4px 8px"
                        fontSize: 18
                        backgroundColor: hsv2rgb(hues[idx], .7, .5)
                        color: 'white'
                        display: 'inline-block'
                        opacity: if @local.search.length > 0 && sub.name.toLowerCase().indexOf(@local.search.toLowerCase()) == -1 then .3   
                      sub.name

            else if @local.hover_second == 'change application'
              UL null,

                for app, idx in apps.apps
                  LI
                    style: 
                      display: 'inline-block'
                      listStyle: 'none'
                    A
                      href: "/set_app/#{app}"
                      'data-nojax': false
                      style: 
                        padding: "4px 8px"
                        fontSize: 18
                        backgroundColor: hsv2rgb(hues[idx], .7, .5)
                        color: 'white'
                        display: 'inline-block'            
                      app

  componentDidMount : ->

    # cycle through subdomains 
    document.addEventListener "keypress", (e) -> 
      key = (e and e.keyCode) or e.keyCode

      if key==14 # cntrl-N        
        app = fetch '/application'

        if app.app == 'franklin'
          subdomains = fetch '/subdomains'
          subdomain = fetch '/subdomain'

          cur_idx = -1
          for sub, idx in subdomains.subs
            if sub.id == subdomain.id
              cur_idx = idx

          next_idx = cur_idx + 1 
          if next_idx >= subdomains.subs.length
            next_idx = 0

          window.location = "/change_subdomain/#{subdomains.subs[next_idx].id}"





window.Development = Development