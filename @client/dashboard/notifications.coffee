window.styles += """
  #NOTIFICATIONS {
    font-size: 18px;
  }

"""

window.Notifications = ReactiveComponent
  displayName: 'Notifications'

  render : -> 

    data = @data()


    settings = {}
    current_user = bus_fetch('/current_user')

    subdomain = bus_fetch('/subdomain')

    prefs = current_user.subscriptions

    loc = bus_fetch('location')
    if loc.query_params?.unsubscribe
      @local.via_unsubscribe_link = true

    if loc.query_params?.unsubscribed
      @local.via_unsubscribe_post = true 


    @local.via_unsubscribe_link = true
    
    DIV 
      id: 'NOTIFICATIONS'

      
      if customization('email_notifications_disabled')
        DIV 
          style: 
            margin: "18px 0 36px 0"
            fontStyle: 'italic'

          TRANSLATE
            id: "email_notifications.disabled"
            "The forum host has disabled email summaries"

      DIV 
        className: 'input_group checkbox'


        DIV 
          style:
            backgroundColor: if @local.via_unsubscribe_link then "var(--bg_container)"
            padding: if @local.via_unsubscribe_link then '12px 18px'
            border: if @local.via_unsubscribe_link then "1px solid var(--selected_color)"
            display: 'flex'
            alignItems: "center"
            flexDirection: 'column'
            gap: 12


          DIV 
            style:
              display: 'flex'
              alignItems: "center"

            INPUT 
              id: 'enable_email'
              type: 'checkbox'
              name: 'enable_email'
              role: 'switch'
              defaultChecked: !!prefs['send_emails']
              "aria-label": translator "email_notifications.send_digests", 'Send me email summaries of relevant forum activity'
              onChange: (e) => 

                if current_user.subscriptions['send_emails']
                  current_user.subscriptions['send_emails'] = false
                else
                  current_user.subscriptions['send_emails'] = settings['default_subscription']
                save current_user
                e.stopPropagation()


            LABEL 
              className: 'indented'
              htmlFor: 'enable_email'
              style: 
                fontSize: 18
              B null,
                TRANSLATE "email_notifications.send_digests", 'Send me email summaries of relevant forum activity'

          if @local.via_unsubscribe_link && !!prefs['send_emails']
            SPAN 
              style:
                backgroundColor: "var(--selected_color)"
                color: "var(--text_light)"
                textTransform: 'uppercase'
                fontSize: '80%'
                fontWeight: 'bold'
                marginLeft: 20
                padding: '2px 8px'
              translator('email_notifications.unsubscribe_helper', 'turn off to unsubscribe')

        if @local.via_unsubscribe_post && !prefs['send_emails']
          DIV 
            style: 
              margin: '24px 48px'

            SPAN
              style:
                backgroundColor: "var(--selected_color)"
                padding: '12px 18px'
                color: "var(--text_light)"

              TRANSLATE
                id: "email_notifications.watched_proposals_ack"
                "You are unsubscribed from summary emails from this forum"



        if prefs['send_emails']
          DIV null,
            
            @drawEmailSettings()

            @drawWatched()



  drawEmailSettings : () -> 
    current_user = bus_fetch('/current_user')

    # make sure events for each trigger are kept up to date with notifier.config
    email_triggers = [
      {
        name: 'new_proposal'
        label: 'A new proposal is added'
        events: ['new_proposal']
      }
      {
        name: 'responds_to_you'
        label: 'Someone responds to something you wrote'
        events: ['new_comment:point_authored', 'new_point:proposal_authored', 'new_opinion:proposal_authored']
      }
      {
        name: 'followed_proposal_activity'
        label: 'Activity on a proposal you are following'
        events: ['new_comment:point_engaged', 'new_comment', 'new_opinion', 'new_point']
      }
    ]

    if current_user.is_admin
      email_triggers.unshift
        name: 'content_to_moderate'
        label: 'When there is new content to help moderate'
        events: ['content_to_moderate']

    settings = current_user.subscriptions

    DIV 
      style: 
        marginTop: 20

      LABEL
        htmlFor: 'send_digests_at_most' 
        style: 
          marginRight: 10
          display: 'inline-block'

        TRANSLATE "email_notifications.digest_timing", "Send email summaries at most"


      SELECT 
        id: 'send_digests_at_most'
        style: 
          width: 120
          fontSize: 18
        value: settings['send_emails']
        onChange: (e) => 
          current_user.subscriptions['send_emails'] = e.target.value
          save current_user

        for u in ['hour', 'day', 'week', 'month']
          OPTION
            key: u
            value: "1_#{u}"
            if u == 'day'
              translator "email_notifications.frequency.daily", 'daily'
            else
              translator "email_notifications.frequency.#{u}ly", "#{u}ly"

      DIV 
        style: 
          marginTop: 20

        DIV
          style: 
            marginBottom: 10

          TRANSLATE 'email_notifications.notable_events', "When should an email summary be triggered?"

        UL
          style: 
            listStyle: 'none'
            marginLeft: 62

          for trigger in email_triggers

            do (trigger) =>

              checked = false
              for evnt in trigger.events
                checked ||= settings[evnt].email_trigger

              LI 
                key: trigger.name
                style: 
                  display: 'block'
                  padding: '10px 0'

                SPAN 
                  style: 
                    display: 'inline-block'
                    verticalAlign: 'top'
                    position: 'relative'

                  INPUT 
                    id: "#{trigger.name}_input"
                    name: "#{trigger.name}_input"
                    type: 'checkbox'
                    className: 'bigger'
                    checked: checked
                    style: 
                      position: 'absolute'
                      left: -30
                      top: 1
                    onChange: => 
                      for evnt in trigger.events
                        settings[evnt].email_trigger = !checked
                      save current_user

                LABEL
                  htmlFor: "#{trigger.name}_input"
                  style: 
                    display: 'inline-block'
                    verticalAlign: 'top'
                    fontSize: 15

                  TRANSLATE "email_notifications.event.#{trigger.name}", trigger.label

  drawWatched: ->
    current_user = bus_fetch('/current_user')
    watched_proposals = []

    for k,v of current_user.subscriptions
      if v == 'watched' && k.match(/\/proposal\//)
        proposal = bus_fetch(k)
        if proposal.name
          watched_proposals.push proposal

    if watched_proposals.length > 0

      DIV 
        style: 
          marginTop: 20

        H2
          style: 
            fontSize: 18
            marginBottom: 32
            fontWeight: 400

          TRANSLATE "email_notifications.watched_proposals", 'Proposals you are following'


        UL
          key: 'follows-list'
          style: 
            position: 'relative'
            marginLeft: 32

          for proposal in watched_proposals when proposal.name
            do (proposal) => 

              LI 
                style: 
                  display: 'flex'
                  marginBottom: 32
                  position: 'relative'

                LABEL 
                  key: 'unfollow-area'
                  htmlFor: "unfollow-#{proposal.name}"

                  SPAN 
                    style: 
                      display: 'none'
                    translator "email_notifications.unfollow_proposal", "Unfollow this proposal"

                  INPUT 
                    key: "unfollow-#{proposal.key}"
                    id: "unfollow-#{proposal.name}"
                    className: 'bigger'
                    style: 
                      marginTop: 4
                    type: 'checkbox'
                    defaultChecked: true
                    "data-tooltip": "Stop receiving updates about this proposal"
                    onChange: => 
                      if !current_user.subscriptions[proposal.key]
                        current_user.subscriptions[proposal.key] = 'watched'
                      else 
                        delete current_user.subscriptions[proposal.key]

                      save current_user

                  SPAN 
                    style: 
                      marginLeft: 18
                      fontSize: 15
                    proposal.name





