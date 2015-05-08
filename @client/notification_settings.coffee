channels = [
  {
    name: 'proposal_in_watchlist',
    label: 'Proposals in my watchlist'
  }, {
    name: 'active_in_proposal',
    label: 'Proposals in which I’ve participated'
  }
]

methods = [
  {
    db: 'email', 
    label: 'Email me'
    }, {
    db: 'on-site', 
    label: 'On-site message'
  }, {
    db: 'none', 
    label: 'Ignore it'
  }
]

events =
  'new_comment_on_my_point': 'Comment on a Pro or Con point I wrote'
  'new_comment_on_point_active_in': 'Comment on a Pro or Con point I\'ve engaged'
  'new_comment': 'Comment on any Pro or Con point'
  'new_point': 'New Pro or Con point'
  'new_opinion': 'New opinion'
  'request': 'New fact-check request'


window.NotificationSettings = ReactiveComponent
  displayName: 'NotificationSettings'

  render : -> 
    data = @data()

    settings = {}
    current_user = fetch('/current_user')

    for channel, idx in channels
      setting = current_user.subscriptions[channel.name]['method']

      if setting.indexOf('_') > -1
        setting = 'email'

      settings[channel.name] = setting

    if !@local.settings? || JSON.stringify(@local.settings) != JSON.stringify(settings)
      @local.settings = settings
      save @local


    DIV null,
      DashHeader name: 'When there is activity related to...'

      DIV 
        style: 
          width: CONTENT_WIDTH
          margin: 'auto'
          fontSize: 18


        for channel in channels
          @drawChannel channel



  drawChannel: (channel) ->

    DIV 
      style: 
        borderBottom: '1px solid #eee'
        padding: '20px 50px'

      DIV
        style: 
          display: 'inline-block'
          width: 200
          textAlign: 'right'
          verticalAlign: 'top'
          marginRight: 80
          paddingTop: 5
        channel.label

      DIV 
        style: 
          display: 'inline-block'
          width: 550

        UL
          style: 
            listStyle: 'none'

          for method in methods
            @drawMethod channel, method

        if @local.settings[channel.name] == 'email'
          @drawEmailSettings channel


  drawMethod: (channel, method) -> 
    current_user = fetch('/current_user')
    selected = @local.settings[channel.name] == method.db

    LI 
      style: 
        padding: '10px 20px 5px 20px'
        display: 'inline-block'
        cursor: 'pointer'
        backgroundColor: if selected then '#eee'

      onClick: => 
        if !selected
          usetting = current_user.subscriptions[channel.name]
          
          usetting['method'] =  if method.db == 'email'
                                  usetting['default']
                                else 
                                  method.db
          save current_user


      DIV
        style: 
          width: 25
          height: 25
          borderRadius: '50%'
          border: '1px solid #ccc'
          display: 'inline-block'
          marginRight: 15
          position: 'relative'
          backgroundColor: 'white'

        if selected
          DIV
            style: 
              width: 15
              height: 15
              borderRadius: '50%'
              backgroundColor: focus_blue
              position: 'absolute'
              left: 4
              top: 4

      SPAN
        style: 
          verticalAlign: 'top'

        method.label

  drawEmailSettings : (channel) -> 
    current_user = fetch('/current_user')        
    settings = current_user.subscriptions[channel.name]
    [num, unit] = settings['method'].split('_')

    specify_triggers = @local.triggers?[channel.name]

    DIV 
      style: 
        backgroundColor: '#eee'
        padding: '10px 10px 10px 60px'

      SPAN 
        style: 
          marginRight: 20
          display: 'inline-block'

        'No more frequently than:'

      INPUT
        type: 'text'
        value: num
        ref: 'num'
        style: 
          padding: 5
          fontSize: 18
          width: 38
        onChange: (e) =>
          # TODO: validate number 
          num = parseInt(e.target.value)
          if !isNaN(num)
            settings['method'] = "#{num}_#{@refs.unit.getDOMNode().value}"
            save current_user

      SPAN 
        style: 
          display: 'inline-block'
          margin: '0 15px'

        'per'

      SELECT 
        style: 
          width: 80
          fontSize: 18
        ref: 'unit'
        value: unit
        onChange: (e) => 
          settings['method'] = "#{@refs.num.getDOMNode().value}_#{e.target.value}"
          save current_user

        for u in ['minute', 'hour', 'day', 'month']
          OPTION
            value: u
            u

      DIV 
        style: 
          marginTop: 5

        DIV 
          style: 
            textDecoration: 'underline'
            cursor: 'pointer'            
          onClick: => 
            @local.triggers ||= {}
            @local.triggers[channel.name] = !@local.triggers[channel.name]
            save @local

          if specify_triggers
            'close'
          else
            'advanced'

        if specify_triggers
          DIV 
            style: 
              margin: '20px 0' 

            DIV
              style: 
                marginBottom: 10

              "Which events should trigger a summary email?"

            UL
              style: 
                listStyle: 'none'

              for event_type, trigger of settings
                continue if event_type in ['method', 'default']

                do (event_type, trigger) =>
                  LI 
                    style: 
                      display: 'block'
                      borderBottom: '1px solid #f1f1f1'
                      padding: '5px 0'

                    SPAN 
                      style: 
                        display: 'inline-block'
                        verticalAlign: 'top'

                      INPUT 
                        id: "#{event_type}_input"
                        type: 'checkbox'
                        checked: if trigger then true
                        style: 
                          fontSize: 24
                        onChange: => 
                          settings[event_type] = !settings[event_type]
                          save current_user

                    LABEL
                      htmlFor: "#{event_type}_input"
                      style: 
                        display: 'inline-block'
                        verticalAlign: 'top'
                        width: 400
                        marginLeft: 15

                      events[event_type]



