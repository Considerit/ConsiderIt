ZipcodeBox = ReactiveComponent
  displayName: 'ZipcodeBox'
  render: ->
    current_user = fetch('/current_user')
    extra_text = if Modernizr.input.placeholder then '' else ' Zip Code'
    onChange = (event) =>
      if event.target.value.match(/\d\d\d\d\d/)
        current_user.tags['zip.editable'] = event.target.value
        save(current_user)

      else if event.target.value.length == 0
        current_user.tags['zip.editable'] = undefined
        @local.stay_around = true
        save(current_user)
        save(@local)

    if current_user.tags['zip.editable'] or @local.stay_around
      # Render the completed zip code box

      DIV
        style: 
          textAlign: 'center'
          padding: '13px 23px'
          fontSize: 20
          fontWeight: 400
          margin: 'auto'
          color: 'white'
        className: 'filled_zip'

        'Customized for:'
        INPUT

          style: 
            fontSize: 20
            fontWeight: 600
            border: '1px solid transparent'
            borderColor: if @local.focused || @local.hovering then '#767676' else 'transparent'
            backgroundColor: if @local.focused || @local.hovering then 'white' else 'transparent'
            width: 80
            marginLeft: 7
            color: if @local.focused || @local.hovering then 'black' else 'white'
            display: 'inline-block'
          type: 'text'
          key: 'zip_input'
          defaultValue: current_user.tags['zip.editable'] or ''
          onChange: onChange
          onFocus: => 
            @local.focused = true
            save(@local)
          onBlur: =>
            @local.focused = false
            @local.stay_around = false
            save(@local)
          onMouseEnter: => 
            @local.hovering = true
            save @local
          onMouseLeave: => 
            @local.hovering = false
            save @local

    else
      # zip code entry
      DIV 
        style: 
          backgroundColor: 'rgba(0,0,0,.1)'
          fontSize: 22
          fontWeight: 700
          width: 720
          color: 'white'
          padding: '15px 40px'
          marginLeft: (WINDOW_WIDTH() - 720) / 2
          #borderRadius: 16

        'Customize this guide for your' + extra_text
        INPUT
          type: 'text'
          key: 'zip_input'
          placeholder: 'Zip Code'
          style: {margin: '0 0 0 12px', fontSize: 22, height: 42, width: 152, padding: '4px 20px'}
          onChange: onChange


window.HomepageHeader = ReactiveComponent
  displayName: 'HomepageHeader'

  render: ->
    LVG_blue = '#063D72'
    LVG_green = '#A5CE39'

    homepage = fetch('location').url == '/'

    DIV 
      style: 
        position: 'relative'

      DIV 
        style: 
          height: if !homepage then 150 else 455 
          backgroundImage: "url(#{asset('livingvotersguide/bg.png')})"
          backgroundPosition: 'center'
          backgroundSize: 'cover'
          backgroundColor: LVG_blue
          textAlign: if homepage then 'center'

        DIV
          style:
            position: 'absolute'
            right: 17
            top: 17
          ProfileMenu({style: {height: 69, left: 0; top: 0, position: 'relative', display: 'inline-block'}})
          
        if !homepage 
          back_to_homepage_button            
            position: 'absolute'
            display: 'inline-block'
            top: 40
            left: 22
            fontSize: 43
            color: 'white'

        # Logo
        A 
          style: 
            marginTop: if homepage then 40 else 10
            display: 'inline-block'
            marginLeft: if !homepage then 80
            marginRight: if !homepage then 30

          href: (if fetch('location').url == '/' then '/about' else '/'),
          IMG 
            src: asset('livingvotersguide/logo.svg')
            style:
              width: if homepage then 220 else 120
              height: if homepage then 220 else 120


        # Tagline
        DIV 
          style:
            display: if !homepage then 'inline-block'
            position: 'relative'
            top: if !homepage then -32
          DIV
            style:
              fontSize: if homepage then 32 else 24
              fontWeight: 700
              color: LVG_green
              margin: '12px 0 4px 0'

            SPAN null, 
              'Washington\'s Citizen Powered Voters Guide'

          DIV 
            style: 
              color: 'white'
              fontSize: if homepage then 20 else 18

            'Learn about your ballot, decide how you’ll vote, and share your opinion.'

        if homepage



          DIV
            style:
              color: 'white'
              fontSize: 20
              marginTop: 30

            DIV
              style: 
                position: 'relative'
                display: 'inline'
                marginRight: 50
                height: 46

              SPAN 
                style: 
                  paddingRight: 12
                  position: 'relative'
                  top: 4
                  verticalAlign: 'top'
                'brought to you by'
              A 
                style: 
                  verticalAlign: 'top'

                href: 'http://seattlecityclub.org'
                IMG 
                  src: asset('livingvotersguide/cityclub.svg')

            DIV 
              style: 
                position: 'relative'
                display: 'inline'
                height: 46
                #display: 'none'

              SPAN 
                style: 
                  paddingRight: 12
                  verticalAlign: 'top'
                  position: 'relative'
                  top: 4

                'fact-checks by'
              
              A 
                style: 
                  verticalAlign: 'top'
                  position: 'relative'
                  top: -6

                href: 'http://spl.org'
                IMG
                  style: 
                    height: 31

                  src: asset('livingvotersguide/spl.png')

      if homepage
        DIV 
          style: 
            backgroundColor: LVG_green

          DIV 
            style: 
              color: 'white'
              margin: 'auto'
              padding: '40px'
              width: 720


            DIV
              style: 
                fontSize: 24
                fontWeight: 600
                textAlign: 'center'

              """The Living Voters Guide has passed on..."""

            DIV 
              style: 
                fontSize: 18
              """We have made the difficult decision to discontinue the Living Voters Guide 
                 after six years of service. Thank you for your contributions through the years!"""

          DIV 
            style: 
              paddingBottom: 15

            ZipcodeBox()

      else
        DIV 
          style: 
            backgroundColor: LVG_green
            paddingTop: 5

window.NonHomepageHeader = HomepageHeader


styles += """
[subdomain="livingvotersguide"] .endorser_group {
  width: 305px;
  display: inline-block;
  margin-bottom: 1em;
  vertical-align: top; }
  [subdomain="livingvotersguide"] .endorser_group.oppose {
    margin-left: 60px; }
  [subdomain="livingvotersguide"] .endorser_group li, [subdomain="livingvotersguide"] .endorser_group a {
    font-size: 12px; }
  [subdomain="livingvotersguide"] .endorser_group ul {
    margin-left: 0px;
    padding-left: 10px; }
[subdomain="livingvotersguide"] .total_money_raised {
  font-weight: 600;
  float: right; }
[subdomain="livingvotersguide"] .funders li {
  list-style: none; }
  [subdomain="livingvotersguide"] .funders li .funder_amount {
    float: right; }
[subdomain="livingvotersguide"] .news {
  padding-left: 0; }
  [subdomain="livingvotersguide"] .news li {
    font-size: 13px;
    list-style: none;
    padding-bottom: 6px; }
[subdomain="livingvotersguide"] .editorials ul {
  padding-left: 10px; }
  [subdomain="livingvotersguide"] .editorials ul li {
    list-style: none;
    padding-top: 6px; }

"""

