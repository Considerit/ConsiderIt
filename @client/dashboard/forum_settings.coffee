


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
    display: flex;
    align-items: flex-start;
  }
  .FORUM_SETTINGS .radio_group label {
    margin-left: 12px;
    margin-top: -2px;
  }

  .FORUM_SETTINGS .radio_group input[type="radio"] {
    margin-top: 0;
  }

  #DASHBOARD-main .FORUM_SETTINGS .field_explanation {
    margin-left: 48px;
  }
 
  .FORUM_SETTINGS .input_group.checkbox {
    display: flex;
  }

  .FORUM_SETTINGS .input_group.checkbox .toggle_switch {
    margin-top: 6px;
  }

  .FORUM_SETTINGS .input_group.checkbox .toggle_switch.disabled{
    opacity: 0.3;
  }

  """

window.ForumSettingsDash = ReactiveComponent
  displayName: 'ForumSettingsDash'

  render : -> 

    subdomain = bus_fetch '/subdomain'
    current_user = bus_fetch '/current_user'

    return SPAN null if !subdomain.name



    DIV 
      className: 'FORUM_SETTINGS'


      # DIV 
      #   style: 
      #     position: 'absolute'
      #     fontSize: 14
      #     fontStyle: 'italic'
      #     top: 80

      #   A 
      #     href: '/dashboard/intake_questions'
      #     style: 
      #       textDecoration: 'underline'
      #       fontWeight: 700
      #     "Sign-up Questions"

      #   " and "
      #   A 
      #     href: '/dashboard/roles'
      #     style: 
      #       textDecoration: 'underline'
      #       fontWeight: 700
      #     "Permissions & Roles"

      #   " have their own settings page"

      # DIV style: marginTop: 64






      ########################
      # Participation with registration

      # do =>
      #   key = "#{subdomain.name}-participation-without-registration"

      #   question_index = ->
      #     for tag, idx in (subdomain.customizations.user_tags or [])
      #       if tag.key == key
      #         return idx
      #     return null

      #   DIV className: 'input_group checkbox',

      #     LABEL 
      #       className: 'toggle_switch'

      #       INPUT 
      #         id: 'enable_unregistered_participation'
      #         type: 'checkbox'
      #         name: 'enable_unregistered_participation'
      #         defaultChecked: customization('unregistered_participation')
      #         onChange: (ev) -> 
      #           subdomain.customizations ||= {}
      #           subdomain.customizations.unregistered_participation = ev.target.checked
      #           save subdomain


      #       SPAN 
      #         className: 'toggle_switch_circle'
          

      #     LABEL 
      #       className: 'indented'

      #       htmlFor: 'enable_unregistered_participation'
      #       B null, 
      #         'Allow participation without registration.'
      #       DIV 
      #         className: 'explanation'

      #         dangerouslySetInnerHTML: __html: """
      #           People are allowed to participate without registering an email or password. 
      #           Works best for small groups where most people know each other. 
      #           If you are considering unregistered participation, recognize that:
      #           <ul style="padding-left: 24px; list-style-position: outside"> 
      #             <li>It will be much easier for someone to participate many times, distorting your results. Including on proposals they submit.</li>
      #             <li>Unregistered participants won't be notified about new activity in the forum, even in response to their own comments.</li>
      #             <li>You will not have access to their email addresses in the data export.</li>
      #           </ul>
      #           """



          
      @drawAnonymitySettings()




      #####################
      # CONTRIBUTION PHASE
      @drawContributionPhaseSettings()



      ########################
      # MODERATION SETTINGS
      @drawModerationSettings()


      @drawMiscSettings()

      ########################
      # Plan
      if current_user.is_super_admin
        DIV 
          className: 'FORUM_SETTINGS_section input_group'

          H4 null, 

            'Forum Plan Type'

          FIELDSET null,

            for option in [{label: 'Free Forum', value: 0}, {label: 'Premium Forum', value: 1}, {label: 'Enterprise Forum', value: 2}]
              DIV 
                key: option.label

                DIV 
                  className: 'radio_group'
                  style: 
                    cursor: 'pointer'

                  onClick: do (option) => => 
                    subdomain.plan = option.value
                    save subdomain


                  INPUT 
                    style: 
                      cursor: 'pointer'
                    type: 'radio'
                    name: "plan"
                    id: "plan_#{option.value}"
                    defaultChecked: subdomain.plan == option.value

                  LABEL 
                    style: 
                      cursor: 'pointer'
                      display: 'block'
                    htmlFor: "plan_#{option.value}"
                    
                    option.label


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
            value: arest.csrf()


          INPUT
            type: 'submit' 

            onSubmit: => 
              confirm("Are you sure you want to rename this forum?")
  

  drawMiscSettings : -> 
    subdomain = bus_fetch '/subdomain'
    current_user = bus_fetch '/current_user'

    lang = @local.language or subdomain.lang or 'en'
    not_english = lang? && lang != 'en'

    DIV 
      className: 'FORUM_SETTINGS_section input_group'

      H4 null, 

        'Other Settings'

      DIV
        className: 'explanation'

        # """
        # These settings control the level of anonymity and visibility of participant identities and opinions in the forum, 
        # ranging from hiding the opinions of others to complete anonymization of authors' identities.
        # """


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
            subdomain.lang = ev.target.value
            save subdomain, -> 
              location.reload()

          style: 
            fontSize: 18
            marginLeft: 12
            display: 'inline-block'


          do => 
            available_languages = Object.assign({}, bus_fetch('/supported_languages').available_languages or {})
            if current_user.is_super_admin
              available_languages['pseudo-en'] = "Pseudo English (for testing)"
              
            for abbrev, label of available_languages
              OPTION
                key: abbrev
                value: abbrev
                label 

        if not_english
          DIV 
            className: 'explanation'

            TRANSLATE
              id: "translations.link"
              percent_complete: Math.round(translation_progress(lang) * 100)
              language: (bus_fetch('/supported_languages').available_languages or {})[lang]
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
            onChange: (ev) -> 
              subdomain.customizations ||= {}
              subdomain.customizations.email_notifications_disabled = ev.target.checked
              save subdomain

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
      # Participation pledge

      do =>
        key = "#{subdomain.name}-pledge_taken"

        question_index = ->
          for tag, idx in (subdomain.customizations.user_tags or [])
            if tag.key == key
              return idx
          return null

        DIV className: 'input_group checkbox',

          LABEL 
            className: 'toggle_switch'

            INPUT 
              id: 'enable_civility_pledge'
              type: 'checkbox'
              name: 'enable_civility_pledge'
              defaultChecked: question_index() != null
              onChange: (ev) -> 
                subdomain.customizations ||= {}
                subdomain.customizations.user_tags ?= []
                if ev.target.checked
                  pledge =
                    key: key
                    no_opinion_view: true
                    visibility: "host-only"
                    participation_pledge: true
                    view_name: 'participation_pledge'
                    self_report: 
                      input: "boolean"
                      question: 'I pledge to be civil and to use only one account'
                      required: true
                  subdomain.customizations.user_tags.push pledge
                else 
                  idx = question_index()
                  if idx != null
                    subdomain.customizations.user_tags.splice(idx, 1)
                    if subdomain.customizations.user_tags.length == 0
                      delete subdomain.customizations.user_tags

                save subdomain


            SPAN 
              className: 'toggle_switch_circle'
          

          LABEL 
            className: 'indented'

            htmlFor: 'enable_civility_pledge'
            B null, 
              'Enable civility pledge.'
            DIV 
              className: 'explanation'
              'Newly registered participants must agree to be civil and to use only one account.'
              

      DIV className: 'input_group checkbox',

        LABEL 
          className: 'toggle_switch'

          INPUT 
            id: 'enable_google_translate'
            type: 'checkbox'
            name: 'enable_google_translate'
            defaultChecked: !customization('disable_google_translate')
            onChange: (ev) -> 
              subdomain.customizations ||= {}
              subdomain.customizations.disable_google_translate = !ev.target.checked
              save subdomain


          SPAN 
            className: 'toggle_switch_circle'
        

        LABEL 
          className: 'indented'

          htmlFor: 'enable_google_translate'
          B null, 
            'Enable Google Translate.'
          SUP 
            style: 
              fontSize: 10
            "Not recommended for EU forums or private forums"
          DIV 
            className: 'explanation'
            """
            Allows participants to view the forum in their preferred language. Forum content is sent to Google’s servers and may be retained to improve translation services.
            For private forums or those under strict data laws (e.g. EU), consider disabling this feature unless user consent is managed.
            """

            
      ########################
      # Plausible analytics
      if current_user.is_super_admin
        DIV className: 'input_group checkbox',

          LABEL 
            className: 'toggle_switch'

            INPUT 
              id: 'enable_plausible'
              type: 'checkbox'
              name: 'enable_plausible'
              defaultChecked: customization('enable_plausible_analytics')
              onChange: (ev) -> 
                subdomain.customizations ||= {}
                subdomain.customizations.enable_plausible_analytics = ev.target.checked
                save subdomain


            SPAN 
              className: 'toggle_switch_circle'
          

          LABEL 
            className: 'indented'

            htmlFor: 'enable_plausible'
            B null, 
              'Collect Advanced Visitation Data.'
            DIV 
              className: 'explanation'
              'Plausible Analytics for this forum.'


  drawAnonymitySettings : -> 
    subdomain = bus_fetch '/subdomain'
    allow_change_anon = not subdomain.customizations.anonymize_permanently
    allow_change_perm_anon = subdomain.customizations.anonymize_everything and (not subdomain.customizations.anonymize_permanently)


    DIV 
      className: 'FORUM_SETTINGS_section input_group'

      H4 null, 

        'Identity and Content Visibility'

      DIV
        className: 'explanation'

        """
        These settings control the level of anonymity and visibility of participant identities and opinions in the forum, 
        ranging from hiding the opinions of others to complete anonymization of authors' identities.
        """


      DIV 
        style: 
          marginTop: 32

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
              onChange: (ev) -> 
                subdomain.customizations ||= {}
                subdomain.customizations.hide_opinions = ev.target.checked
                save subdomain, ->
                  arest.serverFetch('/users') # anonymity may have changed, so force a refetch

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
        # ANONYMIZE EVERYTHING
        DIV 
          className: 'input_group checkbox'
          
          LABEL 
            className: 'toggle_switch' + ( if allow_change_anon  then ''  else ' disabled' )

            INPUT 
              id: 'anonymize_everything'
              type: 'checkbox'
              name: 'anonymize_everything'
              defaultChecked: customization('anonymize_everything')
              disabled: not allow_change_anon
              onChange: (ev) -> 
                subdomain.customizations ||= {}
                subdomain.customizations.anonymize_everything = ev.target.checked
                save subdomain, ->
                  location.reload() # anonymity may have changed, so force a refresh
            
            SPAN 
              className: 'toggle_switch_circle'


          LABEL 
            className: 'indented'
            htmlFor: 'anonymize_everything'
            B null,
              'Conceal identities.'
            
            DIV 
              className: 'explanation'

              "The authors of opinions, points, proposals, and comments will be hidden. Participants still need to be registered. The real identity of authors will still be accessible via the data export. This setting is reversible."

        ########################
        # Anonymize permanently

        DIV 
          className: 'input_group checkbox'
          style: 
            paddingLeft: 70
          
          LABEL 
            className: 'toggle_switch' + ( if allow_change_perm_anon  then ''  else ' disabled' )
            onClick: (ev) -> 
              # Enforce disabled condition
              if not allow_change_perm_anon
                ev.stopPropagation()
                ev.preventDefault()
                return
              # Receives click-events from both label and span, which should be deduplicated to prevent redundant confirmation-dialogs
              # Deduplicate by time between confirm() finish and second event.
              #   Deduplicating by time between events fails, because second event time is delayed until confirm() response.
              #   Deduplicating by target is fragile, assumes specific target order.
              #   Deduplicating by event X/Y coordinates would fail for accessibility cases like keyboard control.
              # If user just ok'd to confirm change... this is a duplicate click event, do not re-prompt to confirm
              now = new Date()
              confirmed = @lastConfirmTime and ( now - @lastConfirmTime < 100 )
              if confirmed
                return confirmed
              # Prompt user for confirmation, and stop click-events if user cancels change
              confirmed = confirm( 'This makes anonymization of this forum permanent. You will not be able to revert. Are you certain?' )
              if confirmed
                @lastConfirmTime = new Date()
              else
                ev.stopPropagation()
                ev.preventDefault()

            INPUT 
              id: 'anonymize_permanently'
              type: 'checkbox'
              name: 'anonymize_permanently'
              defaultChecked: customization('anonymize_permanently')
              disabled: not allow_change_perm_anon
              onChange: (ev) -> 
                subdomain.customizations ||= {}
                if ev.target.checked
                  subdomain.customizations.anonymize_everything = true
                subdomain.customizations.anonymize_permanently = ev.target.checked
                save subdomain, ->
                  arest.serverFetch('/users') # anonymity may have changed, so force a refetch
            
            SPAN 
              className: 'toggle_switch_circle'

          LABEL 
            className: 'indented'
            htmlFor: 'anonymize_permanently'
            B null,
              'Anonymize permanently.'
            
            DIV 
              className: 'explanation'
              "Permanently hide the identities of participants. You will never see the identities of participants. Data export will not reveal the identity of participants. This is irreversible."




        ########################
        # Anonymization theme
        if customization('anonymize_everything')
          DIV 
            className: 'input_group'
            style: 
              paddingLeft: 70

            DIV null,
              LABEL 
                htmlFor: 'anonymization_theme'
                style: 
                  marginRight: 18
                'Anonymization theme'
              

              SELECT 
                id: 'anonymization_theme'
                defaultValue: customization('anonymization_theme')
                style: 
                  fontSize: 18
                  # display: 'block'
                  # marginTop: 4
                onChange: (e) => 
                  subdomain.customizations.anonymization_theme = e.target.value
                  save subdomain, ->
                    location.reload()

                for theme in [{value: null, label: 'Default'}, {value: 'playful', label: 'Cat Masks'}, {value: 'wrestling_masks', label: 'Wrestling Masks'}, {value: 'sea_creatures', label: 'Sea Creatures'}]
                  OPTION
                    key: theme.value
                    value: theme.value
                    theme.label 


            DIV 
              className: 'explanation'
              """Anonymous names and avatars will be assigned to participants, following a specific theme. These 
                 themes help enhance the livliness of the forum. By default, generic gray avatars are used and each 
                 participant is labeled 'Anonymous'."""





  drawContributionPhaseSettings : -> 
    subdomain = bus_fetch '/subdomain'

    phases = [
        {
          label: "Default"
          value: 0
          explanation: "" # "People can contribute as you have configured elsewhere."
        }

        {
          label: "Frozen", 
          value: 'frozen'
          explanation: "No one can add or update anything they have said."
        }
        
        {
          label: "Ideas only"
          value: "ideas-only"
          explanation: "People can only contribute new proposals at this time, and only in places you've allowed it."
        } 
        
        {
          label: "Opinions only"
          value: "opinions-only"
          explanation: "People can only add opinions at this time. They can drag sliders and write pro/con points, but no new proposals."
        } 
        
      ]


    current_value = customization('contribution_phase') || 0


    DIV 
      className: 'FORUM_SETTINGS_section input_group'

      H4 null, 

        'Dialogue State'

      DIV
        className: 'explanation'

        """
        Control the state of your dialogue. This setting gives you the ability to override your configuration elsewhere. 
        For example, if you select "opinions only", no one will be allowed to add new proposals to any of your open-ended questions,
        even if you allowed it when creating your questions. Your settings can be restored by returning to the 
        default state. 
        """


      FIELDSET null,

        for option in phases
          DIV 
            key: option.value

            DIV 
              className: 'radio_group'
              style: 
                cursor: 'pointer'

              onChange: do (option) -> (ev) -> 
                subdomain.customizations ||= {}
                subdomain.customizations.contribution_phase = option.value
                if subdomain.customizations.dialogue_state_explanation
                  delete subdomain.customizations.dialogue_state_explanation
                save subdomain


              INPUT 
                style: 
                  cursor: 'pointer'
                type: 'radio'
                name: "contribution_phase"
                id: "contribution_phase_#{option.value}"
                defaultChecked: current_value == option.value

              LABEL 
                style: 
                  cursor: 'pointer'
                  display: 'block'
                htmlFor: "contribution_phase_#{option.value}"
                
                option.label


            if option.explanation
              DIV 
                className: 'explanation field_explanation'
                option.explanation

                if option.value != 0 && current_value == option.value                

                  TEXTAREA
                    name: 'dialogue_state_explanation'
                    placeholder: "Optional explanation to be displayed to forum visitors"
                    'aria-label': "Optional explanation to be displayed to forum visitors"
                    defaultValue: subdomain.customizations.dialogue_state_explanation
                    
                    onChange: (ev) =>
                      subdomain.customizations ||= {}
                      subdomain.customizations.dialogue_state_explanation = ev.target.value
                      save subdomain

                    style: 
                      marginTop: 6
                      fontSize: 14
                      width: '100%'










  drawModerationSettings : -> 
    subdomain = bus_fetch '/subdomain'
    moderatable_models = ['points', 'comments', 'proposals']

    DIV 
      className: 'FORUM_SETTINGS_section input_group'

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
          DIV 
            key: option.value

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
                  display: 'block'
                htmlFor: "moderation_policy_#{option.value}"
                
                option.label


            if option.explanation
              DIV 
                className: 'explanation field_explanation'
                option.explanation



