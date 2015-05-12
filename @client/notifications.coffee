
first_column_style = 
  display: 'inline-block'
  width: 283
  textAlign: 'right'
  verticalAlign: 'top'
  marginRight: 80
  paddingTop: 5
  fontSize: 18


window.Notifications = ReactiveComponent
  displayName: 'Notifications'

  render : -> 
    data = @data()

    settings = {}
    current_user = fetch('/current_user')

    prefs = current_user.subscriptions

    for digest, digest_config of prefs
      continue if digest == 'subscription_options' || digest.match(/\//)

      settings[digest] ||= {}
      for digest_relation, relation_config of digest_config
        setting = relation_config.subscription

        if setting.indexOf('_') > -1
          setting = 'email'

        settings[digest][digest_relation] = setting

    if !@local.settings? || JSON.stringify(@local.settings) != JSON.stringify(settings)
      @local.settings = settings
      save @local


    DIV 
      style:
        width: CONTENT_WIDTH
        margin: 'auto'

      DIV 
        style: 
          fontSize: 28
          padding: "40px 0"

        DIV 
          style: 
            borderBottom: '1px solid black'
            marginRight: 80
            display: 'inline-block'
          'With activity regarding'

        DIV 
          style: 
            borderBottom: '1px solid black'
            display: 'inline-block'            
          'Notify me by'

      DIV 
        style: 
          fontSize: 18

        for digest in ['subdomain', 'proposal']
          digest_config = prefs[digest]
          for digest_relation, relation_config of digest_config
            @drawChannel digest, digest_relation, \
                         relation_config, prefs.subscription_options
              

        @drawOverrides('watched', "You are currently watching these proposals:")
        @drawOverrides('unsubscribed', "You have unsubscribed to these proposals:")

  drawOverrides: (digest_relation, label) ->
    current_user = fetch('/current_user')
    unsubscribed = {}

    for k,v of current_user.subscriptions
      # we only match proposals for now 
      if v == digest_relation && k.match(/\/proposal\//)
        unsubscribed[k] = v

    if _.keys(unsubscribed).length > 0

      DIV 
        style: 
          padding: '20px 0'

        DIV
          style: first_column_style
          label

        DIV
          style: 
            width: 550
            display: 'inline-block'

          UL
            style: 
              position: 'relative'

            for k,v of unsubscribed
              do (k) => 
                obj = fetch(k)

                LI 
                  style: 
                    listStyle: 'none'
                    padding: '5px 0'

                  A 
                    href: "/#{obj.slug}"
                    style: 
                      textDecoration: 'underline'

                    obj.name 

                  A 
                    style: 
                      cursor: 'pointer'
                      display: 'inline-block'
                      marginLeft: 10
                      fontSize: 14
                    onClick: => 
                      delete current_user.subscriptions[k]
                      save current_user

                    'remove'   


  drawChannel: (digest, digest_relation, relation_config, options) ->

    DIV 
      style: 
        borderBottom: '1px solid #f2f2f2'
        padding: '20px 0px'

      DIV
        style: first_column_style
          

        relation_config.ui_label

      DIV 
        style: 
          display: 'inline-block'
          width: 550

        UL
          style: 
            listStyle: 'none'

          for method, config of options
            selected = @local.settings[digest][digest_relation] == config.name
            @drawMethod digest, digest_relation, config, selected

        if @local.settings[digest][digest_relation] == 'email'
          @drawEmailSettings digest, digest_relation, relation_config


  drawMethod: (digest, digest_relation, method, selected) -> 
    current_user = fetch('/current_user')

    LI 
      style: 
        padding: '10px 20px 5px 20px'
        display: 'inline-block'
        cursor: 'pointer'
        backgroundColor: if selected then '#f2f2f2'

      onClick: => 
        if !selected
          usetting = current_user.subscriptions[digest][digest_relation]
          
          usetting.subscription = if method.name == 'email'
                                    usetting.default_subscription
                                  else 
                                    method.name
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

        method.ui_label

  drawEmailSettings : (digest, digest_relation, relation_config) -> 
    current_user = fetch('/current_user')        
    settings = current_user.subscriptions[digest][digest_relation]
    [num, unit] = relation_config.subscription.split('_')

    specify_triggers = @local.triggers?[digest]?[digest_relation]

    DIV 
      style: 
        backgroundColor: '#f2f2f2'
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
          num = parseInt(e.target.value)
          if !isNaN(num)
            relation_config.subscription = "#{num}_#{unit}"
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
          relation_config.subscription = "#{num}_#{e.target.value}"
          save current_user

        for u in ['hour', 'day', 'month']
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
            @local.triggers[digest] ||= {}
            @local.triggers[digest][digest_relation] = \
                !@local.triggers[digest][digest_relation]
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

              "Which events should trigger an email?"

            UL
              style: 
                listStyle: 'none'


              for event_name, event_relations of relation_config.events
                idx = 0
                for event_relation, event_relation_settings of event_relations
                  idx += 1
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
                        id: "#{event_name}#{idx}_input"
                        type: 'checkbox'
                        checked: if event_relation_settings.email_trigger then true
                        style: 
                          fontSize: 24
                        onChange: do (event_name, event_relation_settings) => => 
                          console.log event_relation_settings
                          event_relation_settings.email_trigger = \
                             !event_relation_settings.email_trigger
                          save current_user

                    LABEL
                      htmlFor: "#{event_name}#{idx}_input"
                      style: 
                        display: 'inline-block'
                        verticalAlign: 'top'
                        width: 400
                        marginLeft: 15

                      event_relation_settings.ui_label



