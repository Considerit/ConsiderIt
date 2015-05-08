EmailNotificationSettings = ReactiveComponent
  displayName: 'EmailNotificationSettings'

  render : -> 
    data = @data()
    current_user = fetch('/current_user')

    DIV null,
      DashHeader name: 'Email Notification Settings'
      DIV style: {width: CONTENT_WIDTH, margin: '15px auto'}, 
        DIV style: {position: 'relative'},
          INPUT 
            id: 'no_email_notifications'
            name: 'no_email_notifications'
            type: 'checkbox'
            defaultChecked: !current_user.no_email_notifications
            style: css.crossbrowserify
              transform: "scale(1.5)"
              fontSize: 30
              position: 'absolute'
              left: -32
              top: 11
            onChange: (e) => 
              current_user.no_email_notifications = \
                !$('#no_email_notifications').is(':checked')
              save current_user

          LABEL 
            htmlFor: 'no_email_notifications'
            style: 
              fontSize: 30
 
            'Enable email notifications'

        if !current_user.no_email_notifications
          if _.flatten(_.values(data.follows)).length == 0
            DIV null, 'You\'re not currently receiving any email notifications'
          else
            DIV null,
              HR null
              for followable_type in ['Point', 'Proposal']
                if data.follows[followable_type].length > 0
                  DIV null,
                    H1 
                      style: 
                        fontSize: 18
                        marginTop: '18px'

                      if followable_type == 'Point'
                        "Pro/con points to which you are subscribed"
                      else
                        "#{followable_type}s to which you have subscribed"
                    for follow in data.follows[followable_type]
                      followable = fetch(follow)
                      DIV style: {margin: '20px 0'}, 
                        if followable_type == 'Point'
                          Point key: followable, rendered_as: 'under_review', enable_dragging: false
                        else 
                          BLOCKQUOTE null,
                            followable.name
                        BUTTON 
                          style: {fontSize: 18}
                          onClick: do(followable) => => 
                            followable.is_following = false
                            save followable
                            arest.serverFetch '/dashboard/email_notifications' 
                               # don't want to have to dirty this key whenever 
                               # a point or proposal is updated
                          'unsubscribe'
