require './auth'

# TODO: this form should also show the community pledge
window.HostQuestions = ReactiveComponent
  displayName: 'CreateAccount'
  mixins: [AuthForm, Modal]

  render: -> 
    i18n = @i18n()
    auth = fetch 'auth'
    current_user = fetch '/current_user'

    @Draw
      task: translator 'auth.additional_info.heading', 'Questions from your host'
      disallow_cancel: true
      goal: if auth.goal then translator "auth.login_goal.#{auth.goal.toLowerCase()}", auth.goal
      on_submit: (ev) =>
        @Submit ev, 
          action: 'user questions'
          has_host_questions: true
          onSuccess: -> 
            auth.show_user_questions_after_account_creation = false
            save auth


      render_below_title: -> 
        host_framing = customization 'host_questions_framing'
        if host_framing 

          DIV 
            style: 
              marginBottom: 12     
              textAlign: if host_framing.length > 80 then 'left'
            DIV 
              style: 
                fontSize: 14
                marginTop: 0
              dangerouslySetInnerHTML: __html: host_framing
        else 
          SPAN null

      DIV null,


        if embedded_demo() && fetch('/subdomain').name == 'galacticfederation' && fetch('local_tags').tags?.federation_allegiance
          switch current_user.tags.federation_allegiance
            when 'Dark'
              avatar_url = "https://d2rtgkroh5y135.cloudfront.net/system/avatars/287330/large/stormtrooper1.png"
              title = 'A Stormtrooper'
              break
            when 'Light' 
              avatar_url = "https://f.consider.it/galacticfederation/ewok.png"  
              title = 'An Ewok'                              
              break
            when "Wouldn't you like to know"
              avatar_url = 'https://f.consider.it/galacticfederation/wookiee.jpeg'
              title = 'A Wookiee'              
              break
            when 'Non-binary' 
              avatar_url = 'https://f.consider.it/galacticfederation/rodian.jpeg'
              title = 'A Rodian'              
              break

          DIV 
            style: 
              display: 'flex'
              alignItems: 'center'
              paddingLeft: 36

            "In this parody, you'll participate as:"

            IMG 
              "data-tooltip": title
              src: avatar_url
              style: 
                height: 70
                marginLeft: 24
                borderRadius: '50%'
      
        ShowHostQuestions
          disable_unchecking_required_booleans: @props.disable_unchecking_required_booleans     



        if customization('auth_footer')
          DIV 
            style:
              fontSize: 13
              color: auth_text_gray
              padding: '16px 0'
            dangerouslySetInnerHTML: {__html: customization('auth_footer')}

        @ShowErrors()


window.forum_has_host_questions = ->
  (tag for tag in (customization('user_tags') or []) when tag.self_report).length > 0

window.errors_in_host_questions = (responses) -> 
  errors = []

  for vals in (customization('user_tags') or [])
    continue if !vals.self_report
    tag = vals.key
    question = vals.self_report
    if question.required
      has_response = question.input in ['checklist'] || !!responses[tag]

      if !has_response || (question.require_checked && !responses[tag])
        errors.push translator 
                       id: 'auth.validation.missing_answer'
                       question: question.question
                       "\"{question}\" is required." 

      is_valid_input = true
      if question.validation
        is_valid_input = question.validation(responses[tag])
      if !is_valid_input && has_response
        errors.push translator 
                       id: 'auth.validation.invalid_answer'
                       response: responses[tag]
                       question: question.question  
                       "{response} isn't a valid answer to \"{question}\"!" 
  errors



styles += """
  #SHOWHOSTQUESTIONS {
    padding: 12px 33px;
    margin-top: 18px;
  }
"""

window.ShowHostQuestions = ReactiveComponent
  displayName: 'ShowHostQuestions'

  render: ->

    host_questions = @HostQuestionInputs()
    return SPAN null if host_questions.length == 0


    

    DIV
      id: 'SHOWHOSTQUESTIONS'

      style: 
        padding: "0px 36px" 

      UL 
        style: 
          padding: "6px 0px"
          listStyle: 'none'

        for [label, render, question] in host_questions
          field_id = render?.props?.id or render?[0]?.props?.id
          LI 
            key: label
            style: 
              marginBottom: 24

            LABEL
              htmlFor: field_id
              style:
                display: 'block'
                fontWeight: 600
                

              SPAN
                style: 
                  paddingRight: if !question.required then 8 
                dangerouslySetInnerHTML: __html: label 


              if question.input != 'boolean'
                if !question.required
                  SPAN 
                    style: 
                      fontSize: 12
                      fontWeight: 400
                      fontStyle: 'italic'
                      color: selected_color

                    translator('auth.optional_field', 'optional') 
                else 
                  SPAN 
                    title: translator('auth.required_field', 'required') 
                    "*"



            render



  ####
  # HostQuestionInputs
  #
  # Creates the ui inputs for answering user questions for this subdomain


  HostQuestionInputs : -> 
    subdomain = fetch('/subdomain')
    current_user = fetch('/current_user')
    auth = fetch('auth')

    local = fetch('local_tags')

    return DIV() if !current_user.tags

    questions = []
    for vals in (customization('user_tags') or [])
      tag = vals.key
      if vals.self_report
        questions.push _.extend {}, vals.self_report, {tag}

    if local.tags != current_user.tags
      local.tags = current_user.tags
      save local
      return SPAN null


    inputs = []
    for question in questions
      do (question) =>
        label = "#{question.question}"      

        switch question.input

          when 'text'
            input = INPUT
              key: label
              style: _.defaults question.input_style or {}, 
                marginBottom: 6
                width: 300
                border: "1px solid #a1a1a1"
                padding: '5px 10px'
                fontSize: 18            
              key: "#{question.tag}_inputBox"
              id: slugify("#{question.tag}inputBox")
              type: 'text'
              value: local.tags[question.tag]

              onChange: do(question) => (event) =>
                # local.tags = local.tags or {}
                local.tags[question.tag] = current_user.tags[question.tag] = event.target.value
                save local
              onKeyPress: (event) =>
                # submit on enter
                if event.which == 13
                  @submitAuth(event)

          when 'boolean'
            input = 

              DIV 
                key: label
                style: 
                  marginBottom: 10

                INPUT
                  id: slugify("#{question.tag}inputBox")
                  key: "#{question.tag}_inputBox"
                  type:'checkbox'
                  className: 'bigger'
                  style: 
                    fontSize: 24
                    verticalAlign: 'top'
                    marginTop: 5
                    marginLeft: 0
                    marginRight: 6
                  checked: local.tags[question.tag]
                  onChange: do(question) => (event) =>
                    # local.tags = local.tags or {}
                    local.tags[question.tag] = current_user.tags[question.tag] = event.target.checked
                    save local

                LABEL 
                  htmlFor: slugify("#{question.tag}inputBox")
                  style: 
                    display: 'inline-block'
                    width: '90%'
                    paddingLeft: 8

                  SPAN 
                    dangerouslySetInnerHTML: __html: question.question

                  if !question.required
                    SPAN 
                      style: 
                        fontSize: 12
                        fontWeight: 400
                        fontStyle: 'italic'
                        color: selected_color

                      translator('auth.optional_field', 'optional') 
                  else 
                    SPAN 
                      title: translator('auth.required_field', 'required') 
                      "*"


            label = ''

          when 'checklist'
            input = DIV 
              key: label
              style: 
                margin: "10px 18px"

              for option in question.options
                do (option) =>
                  key = "#{question.tag}-#{option}"

                  options_checked = (opt.split(OTHER_SEPARATOR)[0] for opt in current_user.tags[question.tag]?.split(CHECKLIST_SEPARATOR) or [])
                  is_checked = options_checked.indexOf(option) > -1
                  DIV 
                    key: key

                    INPUT
                      id: slugify("#{key}-inputBox")
                      key: "#{key}_inputBox"
                      type:'checkbox'
                      className: 'bigger'
                      style: 
                        fontSize: 24
                        verticalAlign: 'baseline'
                        marginLeft: 0
                      checked: is_checked
                      onChange: do(question, option) => (event) =>

                        if event.target.checked
                          options_checked.push option
                        else 
                          idx = options_checked.indexOf(option)
                          if idx > -1
                            options_checked.splice idx, 1
                        
                        local.tags[question.tag] = current_user.tags[question.tag] = options_checked.join(CHECKLIST_SEPARATOR)
                        save local

                        if question.open_text_option == option && event.target.checked
                          int = setInterval =>
                            if @refs["open_value-#{question.tag}"] && !@refs["open_value-#{question.tag}"].getAttribute('disabled')
                              @refs["open_value-#{question.tag}"].focus()
                              clearInterval(int)
                          , 10

                    LABEL 
                      htmlFor: slugify("#{key}-inputBox")
                      style: 
                        display: 'inline'
                        paddingLeft: 8
                      dangerouslySetInnerHTML: __html: option

                    if question.open_text_option == option
                      idx = options_checked.indexOf(option)
                      INPUT 
                        ref: "open_value-#{question.tag}"
                        disabled: !is_checked 
                        defaultValue: current_user.tags[question.tag]?.split(CHECKLIST_SEPARATOR)[idx]?.split(OTHER_SEPARATOR)[1] or ""
                        style: 
                          display: 'inline-block'
                          marginLeft: 12
                        type: 'text'
                        onChange: do(question, option) => (event) =>
                          
                          full_vals = options_checked.slice()
                          full_vals[idx] = "#{full_vals[idx]}#{OTHER_SEPARATOR}#{event.target.value}"
                          local.tags[question.tag] = current_user.tags[question.tag] = full_vals.join(CHECKLIST_SEPARATOR)
                          save local
                        

          when 'dropdown'
            input = DIV null,

              SELECT
                id: slugify("#{question.tag}inputBox")
                key: "#{question.tag}_inputBox"            
                style: _.defaults question.input_style or {},
                  fontSize: 18
                  marginTop: 4
                  maxWidth: '100%'
                  marginRight: 12
                defaultValue: (local.tags[question.tag] or '').split(OTHER_SEPARATOR)[0]
                onChange: do(question) => (event) =>
                  # local.tags = local.tags or {}
                  local.tags[question.tag] = current_user.tags[question.tag] = event.target.value
                  save local

                  if question.open_text_option == event.target.value
                    int = setInterval =>
                      if @refs["open_value-#{question.tag}"] && !@refs["open_value-#{question.tag}"].getAttribute('disabled')
                        @refs["open_value-#{question.tag}"].focus()
                        clearInterval(int)
                    , 10


                [
                  OPTION 
                    key: 'none'
                    value: ''
                    disabled: true 
                    hidden: true
                  for value in question.options
                    OPTION  
                      key: value
                      value: value
                      value
                ]

              if question.open_text_option && question.open_text_option == local.tags[question.tag]?.split(OTHER_SEPARATOR)[0]
                INPUT 
                  ref: "open_value-#{question.tag}"
                  defaultValue: current_user.tags[question.tag]?.split(OTHER_SEPARATOR)[1] or ""
                  style: 
                    display: 'inline-block'
                  type: 'text'
                  onChange: do(question) => (event) =>
                    new_val = "#{local.tags[question.tag].split(OTHER_SEPARATOR)[0]}#{OTHER_SEPARATOR}#{event.target.value}"
                    local.tags[question.tag] = current_user.tags[question.tag] = new_val

                    # console.log "updated to", local.tags[question.tag], current_user.tags[question.tag]
                    save local


          else
            throw "Unsupported question type: #{question.input} for #{question.tag}"

        # if !question.required && question.input not in ['boolean', 'checklist']
        #   op = DIV 
        #         style: 
        #           color: '#888'
        #           fontSize: 12
        #         translator('optional', 'optional')

        #   label = [op, label] 

        inputs.push [label, input, question]
    inputs


CHECKLIST_SEPARATOR = ' ;;; ' # the separator for different options selected by the user for checklists
OTHER_SEPARATOR = ' :: '    # the separator for "other" fields that require text entry for checklists and dropdowns

