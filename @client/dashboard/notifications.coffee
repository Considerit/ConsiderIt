require '../collapsed_proposal'


window.styles += """
  #NOTIFICATIONS {
    font-size: 18px;
  }
  #NOTIFICATIONS .toggle_switch {
    top: -1px;
  }

"""

window.Notifications = ReactiveComponent
  displayName: 'Notifications'

  render : -> 

    data = @data()


    settings = {}
    current_user = fetch('/current_user')

    subdomain = fetch('/subdomain')

    prefs = current_user.subscriptions

    loc = fetch('location')

    if loc.query_params?.unsubscribe
      if current_user.subscriptions['send_emails']
        current_user.subscriptions['send_emails'] = null 
        save current_user
        @local.watched_proposals = true 
        save @local 
      delete loc.query_params.unsubscribe
      save loc

    DIV 
      id: 'NOTIFICATIONS'

      if @local.watched_proposals && !current_user.subscriptions['send_emails']
        DIV 
          style: 
            border: "1px solid #{logo_red}" 
            color: logo_red
            padding: '4px 8px'

          TRANSLATE
            id: "email_notifications.watched_proposals_ack"
            subdomain_name: subdomain.name
            "You are unsubscribed from summary emails from this forum"
      
      if customization('email_notifications_disabled')
        DIV 
          style: 
            margin: "18px 0 36px 0"
            fontStyle: 'italic'
          "The forum host has disabled email summaries"

      DIV 
        className: 'input_group checkbox'
        
        LABEL 
          className: 'toggle_switch'

          INPUT 
            id: 'enable_email'
            type: 'checkbox'
            name: 'enable_email'
            defaultChecked: !!prefs['send_emails']
            onChange: (e) => 

              if current_user.subscriptions['send_emails']
                current_user.subscriptions['send_emails'] = false
              else
                current_user.subscriptions['send_emails'] = settings['default_subscription']
              save current_user
              e.stopPropagation()
          
          SPAN 
            className: 'toggle_switch_circle'


        LABEL 
          className: 'indented'
          htmlFor: 'enable_email'
          style: 
            fontSize: 18
          B null,
            TRANSLATE "email_notifications.send_digests", 'Send me email summaries of relevant forum activity'



        if prefs['send_emails']
          DIV 
            style: 
              marginLeft: 71
            
            @drawEmailSettings()

            @drawWatched()



  drawEmailSettings : () -> 
    current_user = fetch('/current_user')

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
    current_user = fetch('/current_user')
    watched_proposals = []

    for k,v of current_user.subscriptions
      if v == 'watched' && k.match(/\/proposal\//)
        proposal = fetch(k)
        if proposal.name
          watched_proposals.push proposal

    if watched_proposals.length > 0

      DIV 
        style: 
          marginTop: 20

        H4
          style: 
            fontSize: 18
            marginBottom: 32
            fontWeight: 400

          TRANSLATE "email_notifications.watched_proposals", 'Proposals you are following'


        UL
          key: 'follows-list'
          style: 
            position: 'relative'
            marginLeft: 62

          for proposal in watched_proposals
            do (proposal) => 

              if proposal.name
                CollapsedProposal 
                  key: "unfollow-#{proposal.key or proposal}"
                  proposal: proposal
                  show_category: true
                  width: 500
                  hide_scores: true
                  hide_icons: true
                  hide_metadata: true
                  show_category: false
                  icon: =>
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
                          position: 'absolute'
                          left: -30
                          top: 4
                        type: 'checkbox'
                        defaultChecked: true
                        onChange: => 
                          if !current_user.subscriptions[proposal.key]
                            current_user.subscriptions[proposal.key] = 'watched'
                          else 
                            delete current_user.subscriptions[proposal.key]

                          save current_user
