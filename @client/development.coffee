######
# Development 
#
# Adds an invisible development menu in dev environments that shows up when
# you move the mouse into the upper right of the page

require './shared'

Development = ReactiveComponent
  displayName: 'Development'

  render : -> 
    subdomains = fetch '/subdomains'
    apps = fetch '/apps'

    hues = getNiceRandomHues Math.max(subdomains.subs?.length, apps.apps?.length)

    DIV 
      style: 
        position: 'absolute'
        zIndex: 9999
        left: 0
        top: 0
        opacity: if @local.hover_top then 1 else 0
        backgroundColor: 'black'
        color: 'white'
        padding: 10

      onMouseEnter: (e) => @local.hover_top = true; save @local
      onMouseLeave: (e) => @local.hover_top = @local.hover_second = false; save @local

      if @local.hover_top
        SPAN null,
          UL
            style: 
              listStyle: 'none'
              display: 'inline-block'

            for submenu in ['change subdomain', 'change application']
              LI
                style:
                  display: 'inline-block'
                  padding: '0px 18px'
                  backgroundColor: 'black'
                  color: 'white'
                  fontWeight: 600
                onMouseEnter: do(submenu) => (e) => 
                  @local.hover_second = submenu
                  save @local

                submenu       

          DIV 
            style: 
              display: 'inline-block'

            if @local.hover_second == 'change subdomain'
              UL null,              

                for sub, idx in subdomains.subs
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
                        backgroundColor: hsv_to_rgb(hues[idx], .7, .5)
                        color: 'white'
                        display: 'inline-block'            
                      sub.name

            if @local.hover_second == 'change application'
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
                        backgroundColor: hsv_to_rgb(hues[idx], .7, .5)
                        color: 'white'
                        display: 'inline-block'            
                      app

window.Development = Development