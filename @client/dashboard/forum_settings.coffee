


window.styles += """
  .forum_settings_dash { font-size: 18px }
  .forum_settings_dash input[type="text"], .forum_settings_dash textarea { border: 1px solid #aaa; display: block; width: #{HOMEPAGE_WIDTH()}px; font-size: 18px; padding: 4px 8px; } 
  .forum_settings_dash .input_group { 
    margin-bottom: 24px; 
    position: relative;
  }
  .forum_settings_dash .input_group.checkbox input {
    left: -28px;
    top: 3px;
    position: absolute;
  }
  .forum_settings_dash .input_group.checkbox label {
  }        
  .forum_settings_dash .input_group.checkbox label b {
    font-weight: 700;
  }
  """

window.AppSettingsDash = ReactiveComponent
  displayName: 'AppSettingsDash'

  render : -> 

    subdomain = fetch '/subdomain'
    current_user = fetch '/current_user'

    lang = @local.language or subdomain.lang
    not_english = lang? && lang != 'en'

    return SPAN null if !subdomain.name

    DIV className: 'forum_settings_dash',        

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
            style: 
              fontSize: 16

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
          style: 
            fontSize: 16
            color: '#888'
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
          
          LABEL htmlFor: 'google_analytics_code', "Google analytics. Add your Google analytics tracking code."
          INPUT 
            id: 'google_analytics_code'
            type: 'text'
            name: 'google_analytics_code'
            defaultValue: subdomain.google_analytics_code
            placeholder: 'Google Analytics tracking code'
      else 
        DIV className: 'input_group',
          LABEL htmlFor: 'google_analytics_code', "Google analytics tracking code"
          DIV style: {fontStyle: 'italic', fontSize: 15},
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
      DIV className: 'input_group checkbox',
        
        INPUT 
          id: 'anonymize_everything'
          type: 'checkbox'
          name: 'anonymize_everything'
          defaultChecked: customization('anonymize_everything')

        LABEL 
          htmlFor: 'anonymize_everything'
          B null,
            'Anonymize everything.'
          SPAN null, 
            " The authors of opinions, points, proposals, and comments will be hidden. Participants still need to be registered. The real identity of authors will still be accessible via the data export."

      ########################
      # HIDE OPINIONS OF EVERYONE
      DIV className: 'input_group checkbox',
        
        INPUT 
          id: 'hide_opinions'
          type: 'checkbox'
          name: 'hide_opinions'
          defaultChecked: customization('hide_opinions')

        LABEL 
          htmlFor: 'hide_opinions'
          B null, 
            'Hide the opinions of others.'
          SPAN null,
            ' The authors of proposals, points, and comments are still shown, but opinions of others are hidden. Hosts, like you, however, will be able to see the opinions of everyone.'

      ########################
      # FREEZE FORUM
      DIV className: 'input_group checkbox',
        
        INPUT 
          id: 'frozen'
          type: 'checkbox'
          name: 'frozen'
          defaultChecked: customization('frozen')

        LABEL 
          htmlFor: 'frozen'
          
          B null,
            'Freeze forum'

          SPAN null,
            " so that no one can add or change opinions, points, proposals, or comments."


      ########################
      # DISABLE EMAIL NOTIFICATIONS
      DIV className: 'input_group checkbox',
        
        INPUT 
          id: 'email_notifications_disabled'
          type: 'checkbox'
          name: 'email_notifications_disabled'
          defaultChecked: customization('email_notifications_disabled')

        LABEL 
          htmlFor: 'email_notifications_disabled'
          B null,
            'Disable email notifications.'

          SPAN null,
            " Participants will not be notified via email about activity on this forum."


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
            


  submit : -> 
    submitting_files = @submit_logo || @submit_masthead

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

      @local.save_complete = true if !submitting_files
      save @local

      arest.serverFetch('/users') # anonymity may have changed, so force a refetch

      if submitting_files
        current_user = fetch '/current_user'
        $('#subdomain_files').ajaxSubmit
          type: 'PUT'
          data: 
            authenticity_token: current_user.csrf
          success: =>
            location.reload()
          error: => 
            @local.file_errors = true
            save @local
