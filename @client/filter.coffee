require './shared'
require './customizations'


UserFilter = ReactiveComponent
  displayName: 'UserFilter'

  render : -> 

    filters = customization 'user_filters'
    users = fetch '/users'
    filter_out = fetch 'filtered'

    set_filtered_users = => 
      filter_out.users = {}
      filter_out.checked = {}
      filter_funcs = []
      for filter,idx in filters 
        if @refs[idx].getDOMNode().checked
          filter_funcs.push filter.pass
          filter_out.checked[filter.label] = true

      if filter_funcs.length > 0
        for user in users.users
          passes = true 
          for func in filter_funcs
            passes &&= func(user)

          if !passes
            filter_out.users[user.key] = 1

      save filter_out


    DIV 
      style: (@props.style or {})

      SPAN 
        style: 
          textStyle: 'italics'
          marginRight: 10

        'Filter to:'

      for filter,idx in filters 
        do (filter, idx) => 
          id = "filter-#{slugify(filter.label)}"
          DIV 
            ref: "filter-#{idx}"
            style: 
              display: 'inline-block'
              marginRight: 10
            onMouseEnter: => 
              if filter.tooltip 
                tooltip = fetch 'tooltip'
                tooltip.coords = $(@refs["filter-#{idx}"].getDOMNode()).offset()
                tooltip.tip = filter.tooltip
                save tooltip
            onMouseLeave: => 
              if filter.tooltip 
                tooltip = fetch 'tooltip'
                tooltip.coords = tooltip.tip = null 
                save tooltip

            INPUT 
              type: 'checkbox'
              ref: idx
              id: id
              style: 
                fontSize: 24
                marginRight: 6
                display: 'inline-block'
                cursor: 'pointer'

              defaultChecked: filter_out.checked?[filter.label]
              onChange: set_filtered_users

            LABEL 
              htmlFor: id
              style: 
                cursor: 'pointer'

              filter.label

      DIV 
        style: 
          marginTop: 0
          position: 'relative'

        SPAN 
          style: 
            color: "#8D8D8D"
            fontSize: 14

          "read more about "
          SPAN 
            style: 
              textDecoration: 'underline'
              cursor: 'pointer'
              color: if @local.describe_process then logo_red
            onClick: => 
              @local.describe_process = !@local.describe_process
              save @local
            "filters and our process" 
            if @local.describe_process
              " (close)"

        if @local.describe_process
          para = 
            marginBottom: 20

          DIV 
            style: 
              position: 'absolute'
              left: 0
              top: 40
              width: 650
              zIndex: 999
              padding: "20px 40px"
              backgroundColor: '#eee'
              #boxShadow: '0 1px 2px rgba(0,0,0,.3)'
              fontSize: 18

            SPAN 
              style: cssTriangle 'top', '#eee', 16, 8,
                position: 'absolute'
                left: 180
                top: -8


            DIV style: para,

              """Filters help us understand the opinions of the stakeholder groups. \
                 Filters are conjunctive: only users that pass all active filters are shown.
                 These are the filters:"""

            DIV style: para,
              SPAN 
                style:
                  fontWeight: 700
                'Verified users'
              """. Verified users have emailed us a verification image to validate their account.  
                 We have also verified a few other people via other media channels, like Reddit. """
              SPAN style: fontStyle: 'italic', 
                "Verification results shown below."

            DIV style: para,
              SPAN 
                style:
                  fontWeight: 700
                'Miners'

              ". Miners are "
              OL 
                style: 
                  marginLeft: 20 
                LI null,
                  'Users who control a mining pool with > 1% amount of hashrate'
                LI null,
                  'Users who control > 1% amount of hashrate'
              'We verify hashrate by consulting '
              A 
                href: 'https://blockchain.info/pools'
                target: '_blank'
                style: 
                  textDecoration: 'underline'

                'https://blockchain.info/pools'
              '.'

            DIV style: para,
              SPAN 
                style:
                  fontWeight: 700
                'Developers'

              """. Bitcoin developers self-report by editing their user profile. If we recognize 
                 someone as a committer or maintainer of Core or XT, we assign it. 
                 We aren’t satisfied by our criteria for developer. We hope to work with 
                 the community to define a more robust standard for 'reputable technical voice'.""" 

            DIV style: para,
              SPAN 
                style:
                  fontWeight: 700
                'Businesses'

              """. Bitcoin businesses self-report by editing their user profile. Business accounts
                 are either users who operate the business or an account that will represent that 
                 businesses' official position. 
                 We send an email to the listed business(es) to confirm control of the account.""" 

            DIV style: para,
              "These filters aren’t perfect. If you think there is a problem, email us at "
              A
                href: "mailto:admin@consider.it"
                style: 
                  textDecoration: 'underline'
                'admin@consider.it'

              ". We will try to make a more trustless process in the future."

            DIV 
              style: {}

              DIV 
                style: 
                  fontWeight: 600
                  fontSize: 26

                'Verification status'

              for user in users.users 
                user = fetch user 
                if user.tags.verified && user.tags.verified.toLowerCase() not in ['no', 'false']
                  DIV 
                    style:
                      marginTop: 20

                    DIV 
                      style: 
                        fontWeight: 600

                      user.name


                    if user.tags.verified?.indexOf('http') == 0
                      IMG 
                        src: user.tags.verified
                        style: 
                          width: 400
                    else 
                      DIV 
                        style: 
                          fontStyle: 'italic'

                        user.tags.verified







window.UserFilter = UserFilter