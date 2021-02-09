


window.styles += """
  .FORUM_SETTINGS { 
    font-size: 16px;
    max-width: 650px;
  }
  .FORUM_SETTINGS input[type="text"], .FORUM_SETTINGS textarea { 
    border: 1px solid #aaa; 
    display: block; 
    font-size: 18px; 
    padding: 4px 8px; 
  } 
  .FORUM_SETTINGS .input_group { 
    margin-bottom: 24px; 
    position: relative;
  }

  .FORUM_SETTINGS_section {
    margin-top: 36px;
  }
  .FORUM_SETTINGS_section h4 {
    font-size: 18px; 
    font-weight: 600;
  }

  .FORUM_SETTINGS .radio_group {
    margin-top: 24px;
  }
  #DASHBOARD-main .FORUM_SETTINGS .field_explanation {
    margin-left: 36px;
  }
 
  .FORUM_SETTINGS .input_group.checkbox {
    display: flex;
  }

  .FORUM_SETTINGS .input_group.checkbox .toggle_switch {
    margin-top: 6px;
  }

  """

window.ForumSettingsDash = ReactiveComponent
  displayName: 'ForumSettingsDash'

  render : -> 

    subdomain = fetch '/subdomain'
    current_user = fetch '/current_user'

    lang = @local.language or subdomain.lang
    not_english = lang? && lang != 'en'

    return SPAN null if !subdomain.name



    DIV 
      className: 'FORUM_SETTINGS'

      ##################
      # LANGUAGE
      DIV className: 'input_group',
        LABEL htmlFor: 'lang', 'Primary Language'
        SELECT 
          id: 'lang'
          type: 'text'
          name: 'lang'
          value: lang
          onChange: (ev) =>
            @local.language = ev.target.value 
            save @local
          style: 
            fontSize: 18
            marginLeft: 12
            display: 'inline-block'


          do => 
            available_languages = Object.assign({}, fetch('/translations').available_languages or {})
            if current_user.is_super_admin
              available_languages['pseudo-en'] = "Pseudo English (for testing)"
              
            for abbrev, label of available_languages
              OPTION
                value: abbrev
                label 

        if not_english
          DIV 
            className: 'explanation'

            TRANSLATE
              id: "translations.link"
              percent_complete: Math.round(translation_progress(lang) * 100)
              language: (fetch('/translations').available_languages or {})[lang]
              link: 
                component: A 
                args: 
                  href: "/dashboard/translations"
                  style:
                    textDecoration: 'underline'
                    color: focus_color()
                    fontWeight: 700
              "Translations for {language} are {percent_complete}% completed. Help improve the translations <link>here</link>."


        DIV 
          className: 'explanation'
          "Is your preferred language not available? Email us at "
          A
            href: "mailto:hello@consider.it?subject=New language request"
            style: 
              textDecoration: 'underline'
              fontWeight: 600
            "hello@consider.it" 
          " to help us create a translation."



      #######################
      # Google Analytics code
      if subdomain.plan || current_user.is_super_admin
        DIV className: 'input_group',
          
          LABEL htmlFor: 'google_analytics_code', "Google Analytics tracking code"
          INPUT 
            id: 'google_analytics_code'
            type: 'text'
            name: 'google_analytics_code'
            defaultValue: subdomain.google_analytics_code

      else 
        DIV className: 'input_group',
          LABEL htmlFor: 'google_analytics_code', "Google analytics tracking code"
          DIV 
            className: 'explanation'
            "Only available for paid plans. Email "
            A 
              href: 'mailto:hello@consider.it'
              style: 
                textDecoration: 'underline'
              'hello@consider.it'
            ' to inquire further.'

      ########################
      # Plan
      if current_user.is_super_admin

        DIV className: 'input_group',
          LABEL htmlFor: 'plan', 'Account Plan (0,1,2)'
          INPUT 
            id: 'plan'
            type: 'text'
            name: 'plan'
            defaultValue: subdomain.plan
            placeholder: '0 for free plan, 1 for custom, 2 for consulting.'


      ########################
      # ANONYMIZE EVERYTHING
      DIV 
        className: 'input_group checkbox'
        
        LABEL 
          className: 'toggle_switch'

          INPUT 
            id: 'anonymize_everything'
            type: 'checkbox'
            name: 'anonymize_everything'
            defaultChecked: customization('anonymize_everything')
          
          SPAN 
            className: 'toggle_switch_circle'


        LABEL 
          className: 'indented'
          htmlFor: 'anonymize_everything'
          B null,
            'Anonymize everything.'
          
          DIV 
            className: 'explanation'

            "The authors of opinions, points, proposals, and comments will be hidden. Participants still need to be registered. The real identity of authors will still be accessible via the data export."

      ########################
      # HIDE OPINIONS OF EVERYONE
      DIV className: 'input_group checkbox',

        LABEL 
          className: 'toggle_switch'

          INPUT 
            id: 'hide_opinions'
            type: 'checkbox'
            name: 'hide_opinions'
            defaultChecked: customization('hide_opinions')
          
          SPAN 
            className: 'toggle_switch_circle'
        

        LABEL 
          className: 'indented'

          htmlFor: 'hide_opinions'
          B null, 
            'Hide the opinions of others.'
          DIV 
            className: 'explanation'
            ' The authors of proposals, points, and comments are still shown, but opinions of others are hidden. Hosts, like you, however, will be able to see the opinions of everyone.'



      ########################
      # FREEZE FORUM
      DIV className: 'input_group checkbox',
        

        LABEL 
          className: 'toggle_switch'

          INPUT 
            id: 'frozen'
            type: 'checkbox'
            name: 'frozen'
            defaultChecked: customization('frozen')
          
          SPAN 
            className: 'toggle_switch_circle'


        LABEL 
          className: 'indented'        
          htmlFor: 'frozen'
          
          B null,
            'Freeze forum.'

          DIV 
            className: 'explanation'
            "No one can add or change opinions, proposals, or comments while the forum is frozen."


      ########################
      # DISABLE EMAIL NOTIFICATIONS
      DIV className: 'input_group checkbox',
        
        LABEL 
          className: 'toggle_switch'

          INPUT 
            id: 'email_notifications_disabled'
            type: 'checkbox'
            name: 'email_notifications_disabled'
            defaultChecked: customization('email_notifications_disabled')
          
          SPAN 
            className: 'toggle_switch_circle'


        LABEL 
          className: 'indented'        
          htmlFor: 'email_notifications_disabled'
          B null,
            'Disable email notifications.'

          DIV 
            className: 'explanation'
            " Participants will not be notified via email about activity on this forum."


      ########################
      # MODERATION SETTINGS
      @drawModerationSettings()


      ########################
      # SAVE Button
      DIV 
        className: 'input_group'
        BUTTON 
          className: 'primary_button button'
          style: 
            backgroundColor: focus_color()
          onClick: @submit

          'Save'

      if @local.save_complete
        DIV style: {color: 'green'}, 'Saved.'

      if @local.file_errors
        DIV style: {color: 'red'}, 'Error uploading files!'

      if @local.errors
        if @local.errors && @local.errors.length > 0
          DIV 
            style: 
              borderRadius: 8
              margin: 20
              padding: 20
              backgroundColor: '#FFE2E2'

            H1 style: {fontSize: 18}, 'Ooops!'

            for error in @local.errors
              DIV 
                style: 
                  marginTop: 10
                error


      if current_user.is_super_admin
        FORM 
          id: 'rename_forum'
          action: '/rename_forum'
          method: 'post'
          style: 
            marginTop: 40

          LABEL
            htmlFor: 'name'
            'Rename forum to: '

          INPUT 
            id: 'name'
            name: 'name'
            type: 'text'
            style: 
              width: 300

          INPUT 
            type: 'hidden'
            name: 'authenticity_token'
            value: current_user.csrf


          INPUT
            type: 'submit' 

            onSubmit: => 
              confirm("Are you sure you want to rename this forum?")
            
  drawModerationSettings : -> 
    subdomain = fetch '/subdomain'
    moderatable_models = ['points', 'comments', 'proposals']

    DIV 
      className: 'FORUM_SETTINGS_section'

      H4 null, 

        'Your Content Moderation Policy'

      DIV
        className: 'explanation'

        """
        Sometimes people post content detrimental to the forum, such as spam or 
        attacks on other participants. Detrimental posts are much rarer than many 
        hosts fear. Yet even if you do not experience detrimental posts, moderating 
        content can help hosts keep a pulse on the dialogue. And it usually takes 
        less time than expected.
        """


      FIELDSET null,

        for option in moderation_options
          DIV null,

            DIV 
              className: 'radio_group'
              style: 
                cursor: 'pointer'

              onClick: do (option) => => 
                subdomain.moderation_policy = option.value

                save subdomain, -> 
                  #saving the subdomain shouldn't always dirty moderations 
                  #(which is expensive), so just doing it manually here
                  arest.serverFetch('/page/dashboard/moderate')  



              INPUT 
                style: 
                  cursor: 'pointer'
                type: 'radio'
                name: "moderation_policy"
                id: "moderation_policy_#{option.value}"
                defaultChecked: subdomain.moderation_policy == option.value

              LABEL 
                style: 
                  cursor: 'pointer'
                htmlFor: "moderation_policy_#{option.value}"
                
                option.label


            if option.explanation
              DIV 
                className: 'explanation field_explanation'
                option.explanation


  submit : -> 

    subdomain = fetch '/subdomain'
    current_user = fetch '/current_user'

    fields = ['plan', 'google_analytics_code', 'lang']

    for f in fields
      el = document.getElementById(f)
      if el 
        subdomain[f] = el.value

    customization_fields = ['frozen', 'email_notifications_disabled', 'hide_opinions', 'anonymize_everything']
    customizations = subdomain.customizations
    for f in customization_fields
      el = document.getElementById(f)
      if el 
        customizations[f] = el.checked

    @local.save_complete = @local.file_errors = false
    save @local

    save subdomain, => 
      if subdomain.errors
        @local.errors = subdomain.errors

      @local.save_complete = true
      save @local

      arest.serverFetch('/users') # anonymity may have changed, so force a refetch