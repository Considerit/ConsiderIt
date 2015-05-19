
require './watch_star'


# Toggle homepage filter to watched proposals
document.addEventListener "keypress", (e) -> 
  key = (e and e.keyCode) or e.keyCode

  if key==23 # cntrl-W
    filter = fetch 'homepage_filter'
    filter.watched = !filter.watched
    save filter



window.Notifications = ReactiveComponent
  displayName: 'Notifications'

  render : -> 
    data = @data()

    settings = {}
    current_user = fetch('/current_user')

    subdomain = fetch('/subdomain')

    prefs = current_user.subscriptions

    DIV 
      style:
        width: CONTENT_WIDTH
        margin: '50px auto'

      DIV
        style: 
          fontSize: 24
          marginBottom: 10
          
        INPUT 
          type: 'checkbox'
          defaultChecked: !!prefs['send_emails']
          id: 'enable_email'
          style: 
            verticalAlign: 'top'
            display: 'inline-block'
            marginTop: 12

          onChange: => 

            if prefs['send_emails'] 
              current_user.subscriptions['send_emails'] = null
            else
              current_user.subscriptions['send_emails'] = settings['default_subscription']
            save current_user

        DIV 
          style: 
            display: 'inline-block'
            paddingLeft: 20

          LABEL
            htmlFor: 'enable_email'              

            'Send me email digests'

            DIV
              style: 
                fontSize: 18
              "summarizing relevant new activity for you at #{subdomain.app_title || subdomain.name}"


      if prefs['send_emails']
        [@drawEmailSettings()

        @drawWatched()]



  drawEmailSettings : () -> 
    current_user = fetch('/current_user')
    settings = current_user.subscriptions

    DIV 
      style: 
        #backgroundColor: '#f2f2f2'
        padding: '10px 10px 10px 60px'

      SPAN 
        style: 
          marginRight: 10
          display: 'inline-block'

        'Send summaries at most'


      SELECT 
        style: 
          width: 80
          fontSize: 18
        value: settings['send_emails']
        onChange: (e) => 
          current_user.subscriptions['send_emails'] = e.target.value
          save current_user

        for u in ['hour', 'day', 'week', 'month']
          OPTION
            value: "1_#{u}"
            if u == 'day'
              'daily'
            else
              "#{u}ly"

      DIV 
        style: 
          marginTop: 15

        DIV
          style: 
            marginBottom: 10

          "Emails are only sent if a notable event occurred. Which events are notable to you?"

        UL
          style: 
            listStyle: 'none'

          # prefs contains keys of objects being watched, and event trigger
          # preferences for different events
          for event in _.keys(settings).sort()
            config = settings[event]

            continue if not config.ui_label

            LI 
              style: 
                display: 'block'
                padding: '5px 0'

              SPAN 
                style: 
                  display: 'inline-block'
                  verticalAlign: 'top'

                INPUT 
                  id: "#{event}_input"
                  type: 'checkbox'
                  checked: if config.email_trigger then true
                  style: 
                    fontSize: 24
                  onChange: do (config) => => 
                    config.email_trigger = !config.email_trigger
                    save current_user

              LABEL
                htmlFor: "#{event}_input"
                style: 
                  display: 'inline-block'
                  verticalAlign: 'top'
                  width: 450
                  marginLeft: 15

                config.ui_label

  drawWatched: ->
    current_user = fetch('/current_user')
    unsubscribed = {}

    for k,v of current_user.subscriptions
      # we only match proposals for now 
      if v == 'watched' && k.match(/\/proposal\//)
        unsubscribed[k] = v

    if _.keys(unsubscribed).length > 0

      DIV 
        style: 
          padding: '20px 0'
          marginLeft: 63

        DIV
          style: 
            position: 'relative'
            paddingBottom: 10
          'The proposals you are watching for new activity:'

        DIV
          style: 
            width: 550
            display: 'inline-block'

          UL
            style: 
              position: 'relative'
              paddingLeft: 37

            for k,v of unsubscribed
              do (k) => 
                obj = fetch(k)

                LI 
                  style: 
                    listStyle: 'none'
                    padding: '5px 0'
                    position: 'relative'

                  WatchStar
                    proposal: obj
                    #icon: 'fa-bell-slash'
                    watch_color: "#777"
                    label: (watching) -> 
                      "Unwatch this proposal"
                    style: 
                      position: 'absolute'
                      left: -35
                      top: 8
                  A 
                    href: "/#{obj.slug}"
                    style: 
                      textDecoration: 'underline'

                    obj.name 

                  # A 
                  #   style: 
                  #     cursor: 'pointer'
                  #     display: 'inline-block'
                  #     marginLeft: 10
                  #     fontSize: 14
                  #   onClick: => 
                  #     delete current_user.subscriptions[k]
                  #     save current_user

                  #   'stop watching'   





window.hasUnreadNotifications = (proposal) ->
  current_user = fetch '/current_user'
  return false unless proposal.notifications?

  unread = (n for n in proposal.notifications when !n.read_at)

  unread.length

window.ActivityFeed = ReactiveComponent
  displayName: 'ActivityFeed'

  render: ->

    current_user = fetch('/current_user')

    if @proposal.notifications?.length == 0
      return SPAN null

    # just mark everything as read when you've opened the proposal
    if hasUnreadNotifications(@proposal)
      for n in @proposal.notifications
        if !n.read_at
          n.read_at = Date.now()
          save n

    DIV 
      style: 
        width: DESCRIPTION_WIDTH
        position: 'relative'
        margin: 'auto'
        marginLeft: if lefty then 300
        marginBottom: 18

      DIV
        style: 
          backgroundColor: "#eee"
          textDecoration: 'underline'
          padding: 10
          fontSize: 18
          textAlign: 'center'
          cursor: 'pointer'

        onClick: => 
          @local.show_notifications = !@local.show_notifications
          save @local

        I 
          className: 'fa-bell-o fa'
          style: 
            display: 'inline-block'
            marginRight: 15

        if @local.show_notifications
          'Hide notifications'
        else
          'Show notifications'

      if @local.show_notifications
        notifications = []

        UL
          style: 
            border: "1px solid #eee"
            listStyle: 'none'
            padding: 20

          for notification in @proposal.notifications

            @drawNotification(notification)

  drawNotification: (notification) -> 
    event_object = fetch "/#{notification.event_object_type.toLowerCase()}/#{notification.event_object_id}"
    protagonist = fetch(event_object.user)

    subdomain = fetch '/subdomain'

    date = prettyDate(notification.created_at)
    loc = fetch('location')


    action = switch notification.event_object_type

      when 'Comment'
        point = fetch(event_object.point)
        SPAN
          style: {}
          "commented on "
          if notification.event_object_relationship == 'point_authored'
            SPAN 
              style: 
                fontWeight: 600
              'your point '

          A 
            style: 
              color: logo_red
              fontWeight: 600
            onClick: (ev) => 
              ev.stopPropagation()
              loc.query_params.selected = point.key
              save loc

            shorten(point.nutshell)

      when 'Proposal'
        SPAN
          style: {}

          if subdomain.name == 'RANDOM2015'
            "uploaded a review from EasyChair"

          else
            "edited this proposal"


      when 'Point'
        SPAN
          style: {}
          "added a new point "
          A 
            style:
              color: logo_red
              fontWeight: 600    
            onClick: (ev) => 
              ev.stopPropagation()
              loc.query_params.selected = event_object.key
              save loc

            shorten(event_object.nutshell)

        
      when 'Opinion'
        'added their opinion'



    LI 
      style: 
        display: 'block'
        padding: '10px 0'



      DIV 
        style: {}

        Avatar
          key: protagonist
          user: protagonist
          hide_tooltip: true
          style: 
            height: 35
            width: 35
            display: 'inline-block'
            verticalAlign: 'top'


        DIV 
          style:
            display: 'inline-block'
            verticalAlign: 'top'
            marginLeft: 20
            width: '80%'

          DIV 
            style: 
              color: '#999'
            date

          "#{protagonist.name} "
          action
